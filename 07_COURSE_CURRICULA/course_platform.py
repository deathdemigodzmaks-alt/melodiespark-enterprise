"""
MelodieSpark Course Platform
Real course delivery system with Stripe payment integration
"""

import os
import json
import yaml
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
import stripe
import sqlite3
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('CoursePlatform')

# Initialize Stripe with real API key
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')

# FastAPI app
app = FastAPI(title="MelodieSpark Course Platform")

# Security
security = HTTPBearer()


@dataclass
class Course:
    id: str
    title: str
    description: str
    duration: int
    price: float
    currency: str
    level: str
    modules: List[Dict]


@dataclass
class Enrollment:
    id: str
    user_id: str
    course_id: str
    enrolled_at: datetime
    progress: float
    completed: bool
    certificate_issued: bool


class CourseDatabase:
    """SQLite database for course enrollments and progress"""
    
    def __init__(self, db_path: str = "courses.db"):
        self.db_path = db_path
        self.init_db()
    
    def init_db(self):
        """Initialize database tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                name TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS enrollments (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                course_id TEXT NOT NULL,
                enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                progress REAL DEFAULT 0,
                completed BOOLEAN DEFAULT FALSE,
                certificate_issued BOOLEAN DEFAULT FALSE,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE(user_id, course_id)
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS progress (
                id TEXT PRIMARY KEY,
                enrollment_id TEXT NOT NULL,
                module_id TEXT NOT NULL,
                lesson_id TEXT NOT NULL,
                completed BOOLEAN DEFAULT FALSE,
                completed_at TIMESTAMP,
                FOREIGN KEY (enrollment_id) REFERENCES enrollments(id),
                UNIQUE(enrollment_id, lesson_id)
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS payments (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                course_id TEXT NOT NULL,
                amount REAL NOT NULL,
                currency TEXT NOT NULL,
                stripe_payment_intent_id TEXT,
                status TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def create_user(self, email: str, name: str = None) -> str:
        """Create a new user"""
        import uuid
        user_id = str(uuid.uuid4())
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute(
                'INSERT INTO users (id, email, name) VALUES (?, ?, ?)',
                (user_id, email, name)
            )
            conn.commit()
            return user_id
        except sqlite3.IntegrityError:
            # User already exists, get their ID
            cursor.execute('SELECT id FROM users WHERE email = ?', (email,))
            result = cursor.fetchone()
            return result[0] if result else user_id
        finally:
            conn.close()
    
    def create_enrollment(self, user_id: str, course_id: str) -> str:
        """Create a new course enrollment"""
        import uuid
        enrollment_id = str(uuid.uuid4())
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute(
                '''INSERT INTO enrollments (id, user_id, course_id)
                   VALUES (?, ?, ?)''',
                (enrollment_id, user_id, course_id)
            )
            conn.commit()
            return enrollment_id
        except sqlite3.IntegrityError:
            # Enrollment already exists
            cursor.execute(
                'SELECT id FROM enrollments WHERE user_id = ? AND course_id = ?',
                (user_id, course_id)
            )
            result = cursor.fetchone()
            return result[0] if result else enrollment_id
        finally:
            conn.close()
    
    def record_payment(self, user_id: str, course_id: str, amount: float, 
                       currency: str, payment_intent_id: str, status: str) -> str:
        """Record a payment"""
        import uuid
        payment_id = str(uuid.uuid4())
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            '''INSERT INTO payments (id, user_id, course_id, amount, currency, 
               stripe_payment_intent_id, status)
               VALUES (?, ?, ?, ?, ?, ?, ?)''',
            (payment_id, user_id, course_id, amount, currency, 
             payment_intent_id, status)
        )
        conn.commit()
        conn.close()
        
        return payment_id
    
    def get_enrollment(self, user_id: str, course_id: str) -> Optional[Enrollment]:
        """Get enrollment details"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            '''SELECT id, user_id, course_id, enrolled_at, progress, 
               completed, certificate_issued
               FROM enrollments 
               WHERE user_id = ? AND course_id = ?''',
            (user_id, course_id)
        )
        result = cursor.fetchone()
        conn.close()
        
        if result:
            return Enrollment(
                id=result[0],
                user_id=result[1],
                course_id=result[2],
                enrolled_at=datetime.fromisoformat(result[3]),
                progress=result[4],
                completed=bool(result[5]),
                certificate_issued=bool(result[6])
            )
        return None
    
    def update_progress(self, enrollment_id: str, module_id: str, 
                       lesson_id: str) -> None:
        """Update lesson progress"""
        import uuid
        progress_id = str(uuid.uuid4())
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute(
                '''INSERT INTO progress (id, enrollment_id, module_id, lesson_id, 
                   completed, completed_at)
                   VALUES (?, ?, ?, ?, TRUE, ?)''',
                (progress_id, enrollment_id, module_id, lesson_id, 
                 datetime.now().isoformat())
            )
            
            # Update overall enrollment progress
            cursor.execute(
                '''UPDATE enrollments 
                   SET progress = (
                     SELECT COUNT(*) * 100.0 / (
                       SELECT COUNT(DISTINCT lesson_id) FROM progress 
                       WHERE enrollment_id = ?
                     )
                     FROM progress 
                     WHERE enrollment_id = ? AND completed = TRUE
                   )
                   WHERE id = ?''',
                (enrollment_id, enrollment_id, enrollment_id)
            )
            
            conn.commit()
        except sqlite3.IntegrityError:
            # Progress already recorded
            pass
        finally:
            conn.close()


class CourseManager:
    """Course content management"""
    
    def __init__(self, curriculum_path: str):
        self.curriculum_path = curriculum_path
        self.courses = self.load_courses()
    
    def load_courses(self) -> Dict[str, Course]:
        """Load courses from YAML curriculum files"""
        courses = {}
        
        # Load validator mastery course
        validator_path = os.path.join(self.curriculum_path, 'validator_mastery/curriculum.yaml')
        if os.path.exists(validator_path):
            with open(validator_path, 'r') as f:
                data = yaml.safe_load(f)
                course = data['course']
                courses[course['id']] = Course(
                    id=course['id'],
                    title=course['title'],
                    description=course['description'],
                    duration=course['duration'],
                    price=course['price'],
                    currency=course['currency'],
                    level=course['level'],
                    modules=course['modules']
                )
        
        return courses
    
    def get_course(self, course_id: str) -> Optional[Course]:
        """Get course by ID"""
        return self.courses.get(course_id)
    
    def list_courses(self) -> List[Course]:
        """List all available courses"""
        return list(self.courses.values())


# Pydantic models for API
class PurchaseRequest(BaseModel):
    course_id: str
    email: str
    name: Optional[str] = None


class ProgressRequest(BaseModel):
    module_id: str
    lesson_id: str


# Initialize components
db = CourseDatabase()
course_manager = CourseManager("07_COURSE_CURRICULA")


@app.get("/courses")
async def list_courses():
    """List all available courses"""
    courses = course_manager.list_courses()
    return {
        "courses": [
            {
                "id": c.id,
                "title": c.title,
                "description": c.description,
                "duration": c.duration,
                "price": c.price,
                "currency": c.currency,
                "level": c.level
            }
            for c in courses
        ]
    }


@app.get("/courses/{course_id}")
async def get_course(course_id: str):
    """Get course details"""
    course = course_manager.get_course(course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return {
        "id": course.id,
        "title": course.title,
        "description": course.description,
        "duration": course.duration,
        "price": course.price,
        "currency": course.currency,
        "level": course.level,
        "modules": course.modules
    }


@app.post("/purchase")
async def purchase_course(request: PurchaseRequest):
    """
    Purchase a course with real Stripe payment
    Creates a Stripe PaymentIntent for real payment processing
    """
    course = course_manager.get_course(request.course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Create or get user
    user_id = db.create_user(request.email, request.name)
    
    # Check if already enrolled
    existing = db.get_enrollment(user_id, request.course_id)
    if existing:
        raise HTTPException(status_code=400, detail="Already enrolled")
    
    # Create Stripe PaymentIntent for REAL payment
    try:
        payment_intent = stripe.PaymentIntent.create(
            amount=int(course.price * 100),  # Convert to cents
            currency=course.currency.lower(),
            metadata={
                'course_id': request.course_id,
                'user_id': user_id,
                'user_email': request.email
            },
            description=f"Course purchase: {course.title}"
        )
        
        return {
            "payment_intent_id": payment_intent.id,
            "client_secret": payment_intent.client_secret,
            "amount": course.price,
            "currency": course.currency,
            "course_id": request.course_id
        }
    except stripe.error.StripeError as e:
        logger.error(f"Stripe error: {e}")
        raise HTTPException(status_code=500, detail="Payment processing failed")


@app.post("/webhook/stripe")
async def stripe_webhook():
    """
    Handle Stripe webhook events
    Processes real payment confirmations and grants course access
    """
    import json
    
    # In production, verify webhook signature
    payload = await request.body()
    event = json.loads(payload)
    
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        
        course_id = payment_intent['metadata']['course_id']
        user_id = payment_intent['metadata']['user_id']
        user_email = payment_intent['metadata']['user_email']
        
        # Record payment
        db.record_payment(
            user_id=user_id,
            course_id=course_id,
            amount=payment_intent['amount'] / 100,
            currency=payment_intent['currency'],
            payment_intent_id=payment_intent['id'],
            status='completed'
        )
        
        # Create enrollment
        enrollment_id = db.create_enrollment(user_id, course_id)
        
        logger.info(f"Course purchased: {course_id} by {user_email}")
        
        return {"status": "success", "enrollment_id": enrollment_id}
    
    return {"status": "ignored"}


@app.get("/enrollment/{course_id}")
async def get_enrollment(course_id: str, credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get enrollment status for a course"""
    # In production, validate JWT token and extract user_id
    user_id = credentials.credentials  # Simplified for demo
    
    enrollment = db.get_enrollment(user_id, course_id)
    if not enrollment:
        raise HTTPException(status_code=404, detail="Not enrolled")
    
    return {
        "enrollment_id": enrollment.id,
        "course_id": enrollment.course_id,
        "progress": enrollment.progress,
        "completed": enrollment.completed,
        "certificate_issued": enrollment.certificate_issued
    }


@app.post("/progress/{enrollment_id}")
async def update_progress(enrollment_id: str, request: ProgressRequest):
    """Update lesson progress"""
    db.update_progress(enrollment_id, request.module_id, request.lesson_id)
    return {"status": "success"}


if __name__ == "__main__":
    # Run the course platform server
    uvicorn.run(app, host="0.0.0.0", port=8000)
