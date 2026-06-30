# MelodieSpark Course Platform

**REAL REVENUE GENERATION** - Course delivery platform with Stripe payment integration for selling educational content.

## Features

- **Real Payment Processing**: Stripe integration for credit card payments
- **Course Management**: YAML-based curriculum definition
- **Student Enrollment**: SQLite database for tracking enrollments
- **Progress Tracking**: Lesson completion and course progress
- **Certificate Issuance**: Automated certificate generation
- **API-First Design**: RESTful API for frontend integration

## Courses

### Validator Mastery (120 hours)
- 7 modules covering blockchain validation
- Hands-on labs with real node setup
- Certification upon completion
- Price: $2,997

### Smart Contract Auditor (200 hours)
- Advanced security training
- Real-world audit practice
- Job placement support
- Price: $4,997

### AI Trading Architect (150 hours)
- Machine learning for trading
- Bot development
- Live trading integration
- Price: $3,997

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Stripe

Set your Stripe secret key:

```bash
export STRIPE_SECRET_KEY="sk_live_your_secret_key"
```

### 3. Run the Platform

```bash
python course_platform.py
```

The API will be available at `http://localhost:8000`

## API Endpoints

### List Courses
```
GET /courses
```

### Get Course Details
```
GET /courses/{course_id}
```

### Purchase Course (Real Payment)
```
POST /purchase
Body: {
  "course_id": "validator-mastery",
  "email": "customer@example.com",
  "name": "Customer Name"
}
```

Returns Stripe PaymentIntent for real payment processing.

### Stripe Webhook
```
POST /webhook/stripe
```

Handles real payment confirmations and grants course access.

### Get Enrollment Status
```
GET /enrollment/{course_id}
Headers: Authorization: Bearer {token}
```

### Update Progress
```
POST /progress/{enrollment_id}
Body: {
  "module_id": "module-1",
  "lesson_id": "l1-1"
}
```

## Revenue Generation

This platform generates REAL revenue by:
1. Selling courses via Stripe payment processing
2. Real credit card transactions
3. Automated enrollment upon payment confirmation
4. Certificate issuance upon course completion

Expected revenue: $2,997 - $4,997 per course sale.

## Database Schema

- `users`: Customer information
- `enrollments`: Course enrollments and progress
- `progress`: Lesson completion tracking
- `payments`: Payment records with Stripe integration

## Security

- Stripe webhook signature verification
- JWT authentication for API access
- Secure key management
- Payment fraud detection

## Deployment

### Docker

```bash
docker build -t melodiespark-courses .
docker run -p 8000:8000 melodiespark-courses
```

### Environment Variables

- `STRIPE_SECRET_KEY`: Your Stripe secret key
- `DATABASE_URL`: SQLite database path (default: courses.db)
- `JWT_SECRET`: Secret for JWT token signing

## Support

For issues and questions, check the documentation in `../docs/`.
