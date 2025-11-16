# System Design - Real-Time Vocabulary Quiz System

**Last Updated**: November 16, 2025  
**Status**: Initial Design  
**Design Confidence**: 78% (Medium-High)

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Component Selection](#2-component-selection)
3. [Technology Stack](#3-technology-stack)
4. [Detailed Component Design](#4-detailed-component-design)
5. [Data Models](#5-data-models)
6. [API Contracts](#6-api-contracts)
7. [Data Flow](#7-data-flow)
8. [Scalability Design](#8-scalability-design)
9. [Performance Optimization](#9-performance-optimization)
10. [Reliability & Error Handling](#10-reliability--error-handling)
11. [Monitoring & Observability](#11-monitoring--observability)
12. [Security Considerations](#12-security-considerations)
13. [Implementation Plan](#13-implementation-plan)

---

## 1. Architecture Overview

### 1.1 High-Level Architecture (GCP-Native)

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT TIER                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Web Client  │  │  Web Client  │  │  Web Client  │  ...     │
│  │  (Mocked)    │  │  (Mocked)    │  │  (Mocked)    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
└─────────┼──────────────────┼──────────────────┼──────────────────┘
          │                  │                  │
          │  WebSocket       │  WebSocket       │  WebSocket
          │  (WSS)           │  (WSS)           │  (WSS)
┌─────────┼──────────────────┼──────────────────┼──────────────────┐
│  GCP LOAD BALANCING & EDGE                                       │
│         ▼                  ▼                  ▼                   │
│  ┌─────────────────────────────────────────────────────┐         │
│  │    Cloud Load Balancer (HTTPS/WebSocket Support)    │         │
│  │    • SSL/TLS Termination                             │         │
│  │    • Cloud Armor (DDoS Protection)                   │         │
│  │    • Session Affinity for WebSocket                  │         │
│  └─────────────────────────────────────────────────────┘         │
│                              │                                    │
│         ┌────────────────────┼────────────────────┐              │
│         │                    │                    │              │
│         ▼                    ▼                    ▼              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Cloud Run   │    │  Cloud Run   │    │  Cloud Run   │       │
│  │  Instance 1  │    │  Instance 2  │    │  Instance N  │       │
│  │              │    │              │    │              │       │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │       │
│  │ │WebSocket │ │    │ │WebSocket │ │    │ │WebSocket │ │       │
│  │ │ Handler  │ │    │ │ Handler  │ │    │ │ Handler  │ │       │
│  │ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │       │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │       │
│  │ │ Scoring  │ │    │ │ Scoring  │ │    │ │ Scoring  │ │       │
│  │ │  Engine  │ │    │ │  Engine  │ │    │ │  Engine  │ │       │
│  │ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │       │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────┐ │       │
│  │ │Leaderboard│ │   │ │Leaderboard│ │    │ │Leaderboard│ │      │
│  │ │  Service │ │    │ │  Service │ │    │ │  Service │ │       │
│  │ └──────────┘ │    │ └──────────┘ │    │ └──────────┘ │       │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘       │
│         │                   │                    │                │
│         └───────────────────┼────────────────────┘                │
│                             │                                     │
│                  COMPUTE TIER (Cloud Run)                         │
└─────────────────────────────┼─────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌────────────────┐    ┌──────────────┐
│ Memorystore   │    │  Cloud SQL     │    │  Pub/Sub     │
│ for Redis     │    │  (PostgreSQL)  │    │  Topics &    │
│ • Sessions    │    │  • Users       │    │  Subs        │
│ • Leaderboard │    │  • Sessions    │    │  • Events    │
│ • Cache       │    │  • Answers     │    │  • Broadcast │
└───────────────┘    └────────────────┘    └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
┌─────────────────────────────┼─────────────────────────────────────┐
│                    GCP OBSERVABILITY                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │Cloud Logging │  │Cloud Monitor │  │ Cloud Trace  │           │
│  │ (Structured) │  │  (Metrics)   │  │ (Tracing)    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└───────────────────────────────────────────────────────────────────┘

                    DATA & MESSAGING TIER (GCP Managed Services)
```

### 1.2 Architectural Principles

- **Separation of Concerns**: Clear boundaries between WebSocket handling, business logic, and data access
- **Stateless Services**: Server instances are stateless; state is externalized to Redis/Database
- **Event-Driven**: Use pub/sub for cross-instance communication
- **Fail-Fast**: Validate early, fail explicitly with clear error messages
- **Horizontal Scalability**: Design supports adding server instances without code changes

### 1.3 Component Layers (DDD-Inspired)

```
┌────────────────────────────────────────────────┐
│          PRESENTATION LAYER                    │
│  - WebSocket Handlers                          │
│  - Message Parsers/Serializers                 │
│  - Connection Manager                          │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          APPLICATION LAYER                     │
│  - Quiz Session Service                        │
│  - Scoring Service                             │
│  - Leaderboard Service                         │
│  - User Session Service                        │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          DOMAIN LAYER                          │
│  - Quiz Session (Aggregate)                    │
│  - Participant (Entity)                        │
│  - Score (Value Object)                        │
│  - Answer (Entity)                             │
│  - Domain Events (ScoreUpdated, etc.)          │
└────────────────┬───────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────┐
│          INFRASTRUCTURE LAYER                  │
│  - Redis Repository                            │
│  - PostgreSQL Repository                       │
│  - Pub/Sub Client                              │
│  - Metrics Collector                           │
└────────────────────────────────────────────────┘
```

---

## 2. Component Selection

### 2.1 Implementation Choice: **Real-Time Quiz Server**

**Rationale**:
- Server is the **core orchestrator** of real-time interactions
- Demonstrates all critical requirements: concurrency, scoring, leaderboard, real-time communication
- More complex than client, showcasing better engineering depth
- Enables testing with multiple simulated clients
- Server-side performance optimization is more critical for scalability

### 2.2 Mocked Components

The following components will be **mocked or simulated**:

1. **Client Applications**
   - Simple test clients for validation
   - Simulate multiple concurrent users
   - Mock WebSocket connections

2. **Quiz Content Service**
   - Static JSON files with predefined questions/answers
   - Simple in-memory quiz repository

3. **User Authentication**
   - Basic user ID assignment (no real auth)
   - Session tokens generated on connection

4. **Database Layer** (Partial Mock)
   - Redis mock for caching
   - In-memory storage option for development
   - PostgreSQL schema defined but can use in-memory substitute

---

## 3. Technology Stack

### 3.1 Server Implementation

**Language**: **Go (Golang)**

**Rationale**:
- **High Performance**: Excellent for concurrent WebSocket connections (goroutines)
- **Low Latency**: Native compiled language, minimal GC pauses
- **Built-in Concurrency**: Channels and goroutines perfect for real-time systems
- **Strong Standard Library**: HTTP/WebSocket support, JSON handling
- **Production-Ready**: Used by many high-scale real-time systems (Discord, Twitch chat backend)
- **Cloud Run Compatible**: Single binary, simple containerization, fast cold starts
- **GCP SDK Support**: Official Google Cloud Go libraries with excellent integration

**Key Libraries**:
```go
// Core Framework
- gorilla/websocket              // WebSocket server implementation
- gin-gonic/gin                  // HTTP router and middleware (lightweight)

// GCP Integration
- cloud.google.com/go/logging    // Cloud Logging integration
- cloud.google.com/go/pubsub     // Pub/Sub client
- cloud.google.com/go/secretmanager // Secret Manager client
- contrib.go.opencensus.io/exporter/stackdriver // Cloud Monitoring & Trace

// Data Layer
- github.com/go-redis/redis/v8   // Redis client (Memorystore)
- github.com/lib/pq              // PostgreSQL driver (Cloud SQL)
- github.com/jackc/pgx/v5        // Alternative PostgreSQL driver with better performance

// Observability
- go.opencensus.io               // Distributed tracing and metrics
- go.uber.org/zap                // Structured logging (Cloud Logging compatible)

// Testing
- github.com/stretchr/testify    // Testing framework
- github.com/testcontainers/testcontainers-go // Integration testing
```

### 3.2 Real-Time Communication

**Protocol**: **WebSocket** (over WSS in production)

**Rationale**:
- Full-duplex, persistent connection ideal for bidirectional real-time updates
- Lower latency than HTTP polling or SSE
- Efficient message framing
- Wide browser support
- Native support in Go

**Message Format**: **JSON** (with potential binary protocol upgrade path)

### 3.3 Data Storage

**Primary Database**: **Cloud SQL for PostgreSQL** (Fully Managed)

**Rationale**:
- **Fully Managed**: Automated backups, patching, high availability
- **ACID Compliance**: Strong consistency for score integrity
- **Rich Querying**: Advanced PostgreSQL features for leaderboard calculations
- **JSONB Support**: Flexible schema for metadata and extensions
- **High Availability**: Automatic failover with regional replicas
- **Cloud SQL Proxy**: Secure connections without managing SSL certificates
- **Connection Pooling**: Built-in connection pooler (PgBouncer)
- **Proven at Scale**: Production-grade managed service

**Configuration**:
```yaml
Instance Type: db-custom-2-7680 (2 vCPU, 7.5 GB RAM)
Storage: SSD (100 GB with auto-expansion)
Backups: Automated daily backups with point-in-time recovery
HA: Regional instance with automatic failover
Private IP: VPC-native for secure access from Cloud Run
```

**Caching Layer**: **Memorystore for Redis** (Fully Managed)

**Rationale**:
- **Fully Managed**: Google-managed Redis with automatic failover
- **In-Memory Speed**: Sub-millisecond latency for session state
- **Pub/Sub Support**: Cross-instance messaging for distributed systems
- **Sorted Sets**: Native leaderboard support (ZADD, ZRANGE)
- **TTL Support**: Automatic session expiry and cleanup
- **Atomic Operations**: Redis commands ensure score update consistency
- **VPC Integration**: Private connectivity from Cloud Run instances
- **High Availability**: Standard tier with automatic failover and replication

**Configuration**:
```yaml
Tier: Standard (High Availability)
Capacity: 5 GB
Version: Redis 6.x
Network: VPC with Private IP
Replica: Automatic read replica for failover
```

### 3.4 Message Broker

**Pub/Sub**: **Cloud Pub/Sub** (Primary) + **Redis Pub/Sub** (Local Broadcast)

**Cloud Pub/Sub Rationale**:
- **Fully Managed**: Google-managed message queue with global availability
- **Scalability**: Automatically scales to handle millions of messages per second
- **At-Least-Once Delivery**: Guaranteed message delivery with acknowledgments
- **Dead Letter Topics**: Automatic handling of failed messages
- **Message Retention**: Configurable retention (up to 7 days)
- **Push/Pull Subscriptions**: Flexible consumption patterns
- **Global Ordering**: Optional ordering keys for sequential processing
- **Integration**: Native integration with Cloud Run, Cloud Functions
- **Cost-Effective**: Pay only for what you use

**Architecture**:
```yaml
Topics:
  - quiz-events-topic          # All quiz-related events
  - session-events-topic       # Session lifecycle events
  - score-updates-topic        # Real-time score updates
  - leaderboard-updates-topic  # Leaderboard recalculation triggers

Subscriptions:
  - quiz-server-sub (Pull)     # Cloud Run instances pull events
  - analytics-sub (Push)       # Push to analytics service
  - dead-letter-sub            # Failed message handling

Configuration:
  - Acknowledgement Deadline: 60 seconds
  - Message Retention: 24 hours
  - Retry Policy: Exponential backoff (min: 10s, max: 600s)
```

**Redis Pub/Sub Usage** (Complementary):
- **Local Broadcast**: Fast, in-memory messaging within same region
- **WebSocket Notifications**: Immediate client notifications from same instance
- **Session-Scoped Events**: Events that don't need global distribution
- **Low-Latency Use Cases**: Sub-10ms message propagation

**Hybrid Strategy**:
1. **Cloud Pub/Sub**: Cross-region events, durable messaging, service-to-service
2. **Redis Pub/Sub**: Same-region WebSocket broadcasts, ephemeral notifications

### 3.5 Monitoring & Observability (GCP Stack)

**Logging**: **Cloud Logging** (formerly Stackdriver Logging)

**Integration**:
```go
import (
    "cloud.google.com/go/logging"
    "go.uber.org/zap"
)

// Structured logging with Cloud Logging integration
logger, _ := zap.NewProduction()
cloudLogger, _ := logging.NewClient(ctx, projectID)
```

**Features**:
- **Structured Logging**: JSON format with automatic field extraction
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Correlation**: Automatic trace correlation with Cloud Trace
- **Log-based Metrics**: Create metrics from log patterns
- **Retention**: Configurable retention (30 days default, up to 3650 days)
- **Export**: BigQuery integration for analytics

**Metrics**: **Cloud Monitoring** (formerly Stackdriver Monitoring)

**Implementation**:
```go
import "contrib.go.opencensus.io/exporter/stackdriver"

// OpenCensus integration
exporter, _ := stackdriver.NewExporter(stackdriver.Options{
    ProjectID: projectID,
})
view.RegisterExporter(exporter)
```

**Custom Metrics**:
```yaml
Application Metrics:
  - websocket_active_connections
  - websocket_messages_per_second
  - quiz_sessions_active
  - answer_submission_latency_ms
  - leaderboard_update_latency_ms
  - score_calculation_duration_ms
  
GCP Metrics (Automatic):
  - Cloud Run: Request count, latency, CPU, memory
  - Cloud SQL: Connections, queries/sec, replication lag
  - Memorystore: Operations/sec, memory usage, cache hits
  - Cloud Pub/Sub: Message publish/delivery rates, latency
```

**Dashboards**:
- **Real-Time Operations**: Active connections, message throughput
- **Performance**: Latency percentiles (P50, P95, P99), error rates
- **Resource Usage**: CPU, memory, network per service
- **Business Metrics**: Quiz sessions, participants, answer rates

**Tracing**: **Cloud Trace** (formerly Stackdriver Trace)

**Implementation**:
```go
import (
    "go.opencensus.io/trace"
    "contrib.go.opencensus.io/exporter/stackdriver"
)

// Distributed tracing setup
trace.ApplyConfig(trace.Config{
    DefaultSampler: trace.ProbabilitySampler(0.1), // 10% sampling
})
```

**Trace Coverage**:
- WebSocket connection lifecycle
- Answer submission → score calculation → leaderboard update
- Database queries (Cloud SQL)
- Cache operations (Memorystore)
- Pub/Sub message publishing and consumption
- External API calls

**Health Checks**: **Cloud Run Native Health Checks**

```go
// Liveness probe
GET /health/live
Response: 200 OK if process is running

// Readiness probe  
GET /health/ready
Response: 200 OK if:
  - Cloud SQL connection pool healthy
  - Memorystore Redis connection active
  - Pub/Sub client initialized
  - Memory usage < 90%
```

**Alerting Policies**:
```yaml
Critical Alerts (PagerDuty):
  - Error rate > 1% for 5 minutes
  - P99 latency > 500ms for 5 minutes  
  - Cloud SQL connection pool exhausted
  - Memorystore unavailable
  - Cloud Run instance crash rate > 10%
  
Warning Alerts (Email/Slack):
  - Error rate > 0.5% for 10 minutes
  - Memory usage > 80%
  - Active connections > 8000 per instance
  - Cloud SQL slow queries > 1s
  - Pub/Sub message age > 5 minutes
```

**Error Reporting**: **Cloud Error Reporting**

- Automatic error grouping and deduplication
- Stack trace analysis
- Error rate trends
- Integration with Cloud Logging

### 3.6 Development & Testing

**Testing**: 
- **Unit Tests**: Go testing package + testify
- **Integration Tests**: Testcontainers for Redis/PostgreSQL
- **Load Testing**: k6 or Artillery for performance validation
- **GCP Integration Tests**: Use GCP emulators (Pub/Sub, Datastore)

**Containerization**: **Docker** + **Cloud Build**

```dockerfile
# Dockerfile optimized for Cloud Run
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /quiz-server ./cmd/server

FROM gcr.io/distroless/base-debian11
COPY --from=builder /quiz-server /quiz-server
EXPOSE 8080
ENTRYPOINT ["/quiz-server"]
```

**Local Development**: 
```yaml
# docker-compose.yml for local development
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: quiz_db
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
  
  pubsub-emulator:
    image: gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators
    command: gcloud beta emulators pubsub start --host-port=0.0.0.0:8085
    ports:
      - "8085:8085"
```

**CI/CD Pipeline**: **Cloud Build**

```yaml
# cloudbuild.yaml
steps:
  # Run tests
  - name: 'golang:1.21'
    entrypoint: 'go'
    args: ['test', '-v', '-race', '-coverprofile=coverage.out', './...']
  
  # Build container image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/quiz-server:$COMMIT_SHA'
      - '-t'
      - 'gcr.io/$PROJECT_ID/quiz-server:latest'
      - '.'
  
  # Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', '--all-tags', 'gcr.io/$PROJECT_ID/quiz-server']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: 'gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'quiz-server'
      - '--image=gcr.io/$PROJECT_ID/quiz-server:$COMMIT_SHA'
      - '--region=us-central1'
      - '--platform=managed'
      - '--allow-unauthenticated'
      - '--set-env-vars=ENV=production'

images:
  - 'gcr.io/$PROJECT_ID/quiz-server:$COMMIT_SHA'
  - 'gcr.io/$PROJECT_ID/quiz-server:latest'

options:
  machineType: 'N1_HIGHCPU_8'
  logging: CLOUD_LOGGING_ONLY
```

**Code Quality**: 
- **golangci-lint**: Static analysis (runs in Cloud Build)
- **gofmt**: Code formatting enforcement
- **go vet**: Error detection
- **Cloud Build**: Automated testing and security scanning
- **Container Analysis**: Vulnerability scanning for container images
- **Secret Detection**: Prevent credential commits

---

## 4. Detailed Component Design

### 4.1 WebSocket Connection Manager

**Responsibilities**:
- Accept and manage WebSocket connections
- Authenticate users (basic validation)
- Route messages to appropriate handlers
- Broadcast messages to participants
- Handle connection lifecycle (connect, disconnect, reconnect)

**Design**:
```go
type ConnectionManager struct {
    connections map[string]*websocket.Conn  // userID -> connection
    sessions    map[string][]string          // sessionID -> userIDs
    mutex       sync.RWMutex                 // Thread-safe access
    upgrader    websocket.Upgrader
    pubsub      *redis.PubSubClient
}

// Key Methods
func (cm *ConnectionManager) HandleConnection(w http.ResponseWriter, r *http.Request)
func (cm *ConnectionManager) SendToUser(userID string, message Message) error
func (cm *ConnectionManager) BroadcastToSession(sessionID string, message Message) error
func (cm *ConnectionManager) RemoveConnection(userID string)
```

**Concurrency Model**:
- Each WebSocket connection runs in a dedicated goroutine
- Read/write goroutines per connection to prevent blocking
- Channel-based message passing for thread safety

### 4.2 Quiz Session Service

**Responsibilities**:
- Create and manage quiz sessions
- Track participants in sessions
- Enforce session lifecycle (waiting → active → completed)
- Validate quiz IDs

**Design**:
```go
type QuizSession struct {
    SessionID    string
    QuizID       string
    Participants map[string]*Participant
    Status       SessionStatus
    StartTime    time.Time
    EndTime      *time.Time
    mu           sync.RWMutex
}

type SessionService struct {
    sessions map[string]*QuizSession
    cache    *redis.Client
    repo     SessionRepository
}

// Key Methods
func (s *SessionService) CreateSession(quizID string) (*QuizSession, error)
func (s *SessionService) JoinSession(sessionID, userID string) error
func (s *SessionService) GetSession(sessionID string) (*QuizSession, error)
func (s *SessionService) LeaveSession(sessionID, userID string) error
```

### 4.3 Scoring Engine

**Responsibilities**:
- Validate answer submissions
- Calculate scores based on correctness
- Apply scoring rules (points per question, time bonus, etc.)
- Emit score update events
- Ensure atomic score updates

**Design**:
```go
type ScoringEngine struct {
    quizRepo    QuizRepository
    scoreRepo   ScoreRepository
    cache       *redis.Client
    eventBus    EventBus
}

// Key Methods
func (se *ScoringEngine) SubmitAnswer(ctx context.Context, submission AnswerSubmission) (*ScoreResult, error)
func (se *ScoringEngine) ValidateAnswer(submission AnswerSubmission) (bool, error)
func (se *ScoringEngine) CalculatePoints(isCorrect bool, timeTaken time.Duration) int
func (se *ScoringEngine) UpdateScore(userID, sessionID string, points int) error
```

**Scoring Algorithm**:
```
Base Points: 10 per correct answer
Time Bonus: max(0, 5 - floor(timeTaken/2seconds)) 
Total: basePoints + timeBonus (if correct), 0 (if incorrect)
```

**Atomicity**:
- Use Redis INCR for atomic score updates
- Optimistic locking for database writes
- Event sourcing pattern for audit trail

### 4.4 Leaderboard Service

**Responsibilities**:
- Maintain real-time rankings
- Calculate leaderboard positions
- Broadcast leaderboard updates
- Support pagination for large sessions

**Design**:
```go
type LeaderboardService struct {
    cache      *redis.Client
    repo       LeaderboardRepository
    pubsub     *redis.PubSubClient
}

// Key Methods
func (ls *LeaderboardService) UpdateRanking(sessionID, userID string, newScore int) error
func (ls *LeaderboardService) GetLeaderboard(sessionID string, limit, offset int) ([]LeaderboardEntry, error)
func (ls *LeaderboardService) BroadcastUpdate(sessionID string) error
```

**Data Structure**:
- Redis Sorted Set: `leaderboard:{sessionID}` with score as sort key
- Cache TTL: Session duration + 1 hour
- Update strategy: Incremental updates on score change

**Optimization**:
- Batch updates (100ms window) to reduce broadcast frequency
- Paginated leaderboard (top 100 by default)
- Delta updates (only changed rankings) for efficiency

### 4.5 Event Bus

**Responsibilities**:
- Publish domain events (ScoreUpdated, UserJoined, SessionEnded)
- Subscribe to events across server instances
- Ensure event ordering per session

**Design**:
```go
type EventBus struct {
    pubsub *redis.PubSubClient
}

type DomainEvent struct {
    Type      EventType
    SessionID string
    Payload   interface{}
    Timestamp time.Time
}

// Key Methods
func (eb *EventBus) Publish(event DomainEvent) error
func (eb *EventBus) Subscribe(eventType EventType, handler EventHandler) error
```

**Event Types**:
- `USER_JOINED`: User joins session
- `USER_LEFT`: User leaves/disconnects
- `ANSWER_SUBMITTED`: Answer submitted
- `SCORE_UPDATED`: Score changed
- `LEADERBOARD_UPDATED`: Rankings changed
- `SESSION_STARTED`: Quiz begins
- `SESSION_ENDED`: Quiz completes

---

## 5. Data Models

### 5.1 Domain Models

**QuizSession**
```go
type QuizSession struct {
    ID           string       `json:"id" db:"id"`
    QuizID       string       `json:"quiz_id" db:"quiz_id"`
    Status       string       `json:"status" db:"status"` // waiting|active|completed
    StartTime    time.Time    `json:"start_time" db:"start_time"`
    EndTime      *time.Time   `json:"end_time,omitempty" db:"end_time"`
    MaxParticipants int       `json:"max_participants" db:"max_participants"`
    CreatedAt    time.Time    `json:"created_at" db:"created_at"`
}
```

**Participant**
```go
type Participant struct {
    ID           string    `json:"id" db:"id"`
    UserID       string    `json:"user_id" db:"user_id"`
    SessionID    string    `json:"session_id" db:"session_id"`
    Username     string    `json:"username" db:"username"`
    Score        int       `json:"score" db:"score"`
    JoinedAt     time.Time `json:"joined_at" db:"joined_at"`
    LastActiveAt time.Time `json:"last_active_at" db:"last_active_at"`
    Status       string    `json:"status" db:"status"` // connected|disconnected
}
```

**AnswerSubmission**
```go
type AnswerSubmission struct {
    ID           string    `json:"id" db:"id"`
    UserID       string    `json:"user_id" db:"user_id"`
    SessionID    string    `json:"session_id" db:"session_id"`
    QuestionID   string    `json:"question_id" db:"question_id"`
    Answer       string    `json:"answer" db:"answer"`
    IsCorrect    bool      `json:"is_correct" db:"is_correct"`
    Points       int       `json:"points" db:"points"`
    SubmittedAt  time.Time `json:"submitted_at" db:"submitted_at"`
    TimeTaken    int       `json:"time_taken_ms" db:"time_taken_ms"` // milliseconds
}
```

**LeaderboardEntry**
```go
type LeaderboardEntry struct {
    Rank      int    `json:"rank"`
    UserID    string `json:"user_id"`
    Username  string `json:"username"`
    Score     int    `json:"score"`
    UpdatedAt time.Time `json:"updated_at"`
}
```

**Quiz** (Mocked)
```go
type Quiz struct {
    ID          string     `json:"id"`
    Title       string     `json:"title"`
    Questions   []Question `json:"questions"`
}

type Question struct {
    ID            string   `json:"id"`
    Text          string   `json:"text"`
    Options       []string `json:"options,omitempty"`
    CorrectAnswer string   `json:"correct_answer"`
    Points        int      `json:"points"`
}
```

### 5.2 Database Schema

**PostgreSQL Tables**:

```sql
-- Quiz Sessions
CREATE TABLE quiz_sessions (
    id VARCHAR(36) PRIMARY KEY,
    quiz_id VARCHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('waiting', 'active', 'completed')),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    max_participants INT DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_quiz_id (quiz_id),
    INDEX idx_status (status)
);

-- Participants
CREATE TABLE participants (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL REFERENCES quiz_sessions(id),
    username VARCHAR(100) NOT NULL,
    score INT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT NOW(),
    last_active_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'connected',
    INDEX idx_session_user (session_id, user_id),
    INDEX idx_user_id (user_id),
    UNIQUE(session_id, user_id)
);

-- Answer Submissions
CREATE TABLE answer_submissions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL REFERENCES quiz_sessions(id),
    question_id VARCHAR(36) NOT NULL,
    answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    points INT NOT NULL,
    submitted_at TIMESTAMP DEFAULT NOW(),
    time_taken_ms INT,
    INDEX idx_session_user (session_id, user_id),
    INDEX idx_question (question_id)
);

-- Leaderboard (Materialized View - Optional)
CREATE MATERIALIZED VIEW leaderboard_snapshot AS
SELECT 
    session_id,
    user_id,
    username,
    score,
    RANK() OVER (PARTITION BY session_id ORDER BY score DESC, joined_at ASC) as rank,
    NOW() as snapshot_time
FROM participants
WHERE status = 'connected';

CREATE INDEX idx_leaderboard_session ON leaderboard_snapshot(session_id, rank);
```

### 5.3 Redis Data Structures

```
# Session State
Key: session:{sessionID}
Type: Hash
Fields: {quiz_id, status, start_time, participant_count}
TTL: 24 hours

# Participant Connection State
Key: participant:{sessionID}:{userID}
Type: Hash
Fields: {username, score, last_active, status}
TTL: Session duration + 1 hour

# Leaderboard
Key: leaderboard:{sessionID}
Type: Sorted Set
Members: userID
Scores: user score
TTL: Session duration + 1 hour

# Active Connections
Key: connections:{serverID}
Type: Set
Members: userID list
TTL: 5 minutes (refreshed via heartbeat)

# Session Lock (for atomic operations)
Key: lock:session:{sessionID}
Type: String
TTL: 5 seconds
```

---

## 6. API Contracts

### 6.1 WebSocket Message Protocol

**Connection**:
```
Endpoint: ws://localhost:8080/ws
Query Params: ?user_id={userId}
```

**Message Format**:
```json
{
  "type": "MESSAGE_TYPE",
  "payload": {...},
  "timestamp": "2025-11-16T10:30:00Z",
  "message_id": "uuid"
}
```

### 6.2 Client → Server Messages

**1. Join Session**
```json
{
  "type": "JOIN_SESSION",
  "payload": {
    "session_id": "quiz-123",
    "username": "john_doe"
  }
}
```

**2. Submit Answer**
```json
{
  "type": "SUBMIT_ANSWER",
  "payload": {
    "session_id": "quiz-123",
    "question_id": "q1",
    "answer": "Paris",
    "time_taken_ms": 3500
  }
}
```

**3. Leave Session**
```json
{
  "type": "LEAVE_SESSION",
  "payload": {
    "session_id": "quiz-123"
  }
}
```

**4. Heartbeat**
```json
{
  "type": "PING",
  "payload": {}
}
```

### 6.3 Server → Client Messages

**1. Session Joined**
```json
{
  "type": "SESSION_JOINED",
  "payload": {
    "session_id": "quiz-123",
    "quiz_id": "vocab-101",
    "status": "active",
    "participant_count": 15,
    "your_score": 0
  }
}
```

**2. Score Update**
```json
{
  "type": "SCORE_UPDATED",
  "payload": {
    "user_id": "user-456",
    "new_score": 25,
    "points_earned": 15,
    "is_correct": true,
    "question_id": "q1"
  }
}
```

**3. Leaderboard Update**
```json
{
  "type": "LEADERBOARD_UPDATED",
  "payload": {
    "session_id": "quiz-123",
    "leaderboard": [
      {"rank": 1, "user_id": "user-123", "username": "alice", "score": 50},
      {"rank": 2, "user_id": "user-456", "username": "bob", "score": 45},
      {"rank": 3, "user_id": "user-789", "username": "carol", "score": 40}
    ],
    "your_rank": 2,
    "total_participants": 15
  }
}
```

**4. User Joined**
```json
{
  "type": "USER_JOINED",
  "payload": {
    "user_id": "user-999",
    "username": "dave",
    "participant_count": 16
  }
}
```

**5. User Left**
```json
{
  "type": "USER_LEFT",
  "payload": {
    "user_id": "user-999",
    "username": "dave",
    "participant_count": 15
  }
}
```

**6. Error**
```json
{
  "type": "ERROR",
  "payload": {
    "code": "INVALID_SESSION",
    "message": "Session quiz-999 does not exist",
    "recoverable": false
  }
}
```

**7. Pong (Heartbeat Response)**
```json
{
  "type": "PONG",
  "payload": {
    "server_time": "2025-11-16T10:30:05Z"
  }
}
```

### 6.4 REST API (Admin/Health)

**Health Check**
```
GET /health
Response: 200 OK
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "active_connections": 150,
  "active_sessions": 12
}
```

**Metrics**
```
GET /metrics
Response: 200 OK (Prometheus format)
```

**Create Session** (Admin)
```
POST /api/v1/sessions
Request:
{
  "quiz_id": "vocab-101",
  "max_participants": 1000
}

Response: 201 Created
{
  "session_id": "quiz-123",
  "quiz_id": "vocab-101",
  "status": "waiting"
}
```

---

## 7. Data Flow

### 7.1 User Join Flow

```
┌────────┐                ┌────────┐              ┌─────────┐          ┌─────────┐
│ Client │                │ Server │              │  Redis  │          │   DB    │
└───┬────┘                └───┬────┘              └────┬────┘          └────┬────┘
    │                         │                        │                    │
    │ 1. WebSocket Connect    │                        │                    │
    │────────────────────────>│                        │                    │
    │                         │                        │                    │
    │ 2. JOIN_SESSION         │                        │                    │
    │────────────────────────>│                        │                    │
    │                         │                        │                    │
    │                         │ 3. Validate Session    │                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │                         │ 4. Session Exists      │                    │
    │                         │ <──────────────────────│                    │
    │                         │                        │                    │
    │                         │ 5. Add Participant     │                    │
    │                         │──────────────────────────────────────────> │
    │                         │                        │                    │
    │                         │ 6. Update Session Cache│                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │                         │ 7. Publish USER_JOINED │                    │
    │                         │──────────────────────> │                    │
    │                         │                        │                    │
    │ 8. SESSION_JOINED       │                        │                    │
    │ <───────────────────────│                        │                    │
    │                         │                        │                    │
    │ 9. USER_JOINED (broadcast to others)             │                    │
    │ <───────────────────────│                        │                    │
    │                         │                        │                    │
```

**Steps**:
1. Client establishes WebSocket connection with user_id query param
2. Client sends JOIN_SESSION message with session_id and username
3. Server validates session exists in Redis cache
4. Redis confirms session exists and status is "active" or "waiting"
5. Server creates participant record in PostgreSQL
6. Server updates session participant count in Redis
7. Server publishes USER_JOINED event to Redis Pub/Sub
8. Server sends SESSION_JOINED confirmation to the joining client
9. All other clients in the session receive USER_JOINED broadcast

**Error Scenarios**:
- Invalid session_id → ERROR response: "Session not found"
- Session full → ERROR response: "Session at capacity"
- User already joined → Reconnect logic (update connection reference)

### 7.2 Answer Submission Flow

```
┌────────┐          ┌────────┐        ┌─────────┐        ┌─────────┐         ┌────────────┐
│ Client │          │ Server │        │  Redis  │        │   DB    │         │Other Clients│
└───┬────┘          └───┬────┘        └────┬────┘        └────┬────┘         └──────┬─────┘
    │                   │                   │                  │                     │
    │ 1. SUBMIT_ANSWER  │                   │                  │                     │
    │──────────────────>│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 2. Validate Question                 │                     │
    │                   │ (from cache/mock) │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 3. Check Answer   │                  │                     │
    │                   │ Correctness       │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 4. Calculate Score│                  │                     │
    │                   │   (base + time)   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 5. Atomic Score Update (INCRBY)      │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 6. New Score      │                  │                     │
    │                   │<──────────────────│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 7. Persist Answer │                  │                     │
    │                   │──────────────────────────────────────>│                     │
    │                   │                   │                  │                     │
    │                   │ 8. Update Leaderboard (ZADD)         │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │                   │ 9. Publish SCORE_UPDATED             │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │ 10. SCORE_UPDATED │                   │                  │                     │
    │<──────────────────│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 11. Publish LEADERBOARD_UPDATED      │                     │
    │                   │──────────────────>│                  │                     │
    │                   │                   │                  │                     │
    │ 12. LEADERBOARD_UPDATED                                  │                     │
    │<──────────────────│                   │                  │                     │
    │                   │                   │                  │                     │
    │                   │ 13. Broadcast to Session             │                     │
    │                   │──────────────────────────────────────────────────────────>│
    │                   │                   │                  │                     │
```

**Steps**:
1. Client submits answer with question_id, answer, and time_taken_ms
2. Server retrieves correct answer from quiz repository (mocked/cached)
3. Server validates answer correctness
4. Server calculates points (base points + time bonus if correct)
5. Server atomically increments user score in Redis using INCRBY
6. Redis returns new total score
7. Server persists answer submission to PostgreSQL (async)
8. Server updates leaderboard sorted set in Redis using ZADD
9. Server publishes SCORE_UPDATED event to Redis Pub/Sub
10. Server sends SCORE_UPDATED message to submitting client
11. Server publishes LEADERBOARD_UPDATED event (may be batched)
12. Server sends updated leaderboard to submitting client
13. All other clients in session receive score and leaderboard updates

**Optimizations**:
- Steps 7 (DB persist) happens asynchronously to reduce latency
- Leaderboard broadcasts are batched (100ms window) to reduce traffic
- Only top 100 leaderboard entries sent to clients

### 7.3 Leaderboard Update Flow

```
┌────────────┐        ┌────────────┐        ┌─────────┐
│  Server    │        │   Redis    │        │ Clients │
│  Instance  │        │  Pub/Sub   │        │ (All)   │
└─────┬──────┘        └─────┬──────┘        └────┬────┘
      │                     │                     │
      │ 1. SCORE_UPDATED    │                     │
      │    event received   │                     │
      │                     │                     │
      │ 2. Add to batch     │                     │
      │    (100ms window)   │                     │
      │                     │                     │
      │ 3. Batch timeout    │                     │
      │    reached          │                     │
      │                     │                     │
      │ 4. ZRANGE           │                     │
      │    leaderboard:xyz  │                     │
      │    0 99 WITHSCORES  │                     │
      │────────────────────>│                     │
      │                     │                     │
      │ 5. Top 100 entries  │                     │
      │<────────────────────│                     │
      │                     │                     │
      │ 6. Compute delta    │                     │
      │    (compare with    │                     │
      │     previous)       │                     │
      │                     │                     │
      │ 7. LEADERBOARD_     │                     │
      │    UPDATED          │                     │
      │──────────────────────────────────────────>│
      │                     │                     │
```

**Batching Strategy**:
- Collect score updates for 100ms
- Fetch leaderboard once per batch
- Calculate delta (changed rankings)
- Broadcast minimal update payload

---

## 8. Scalability Design (GCP-Native)

### 8.1 Horizontal Scaling with Cloud Run

**Strategy**: Serverless containers with automatic scaling

**Cloud Run Auto-Scaling Configuration**:
```yaml
Service: quiz-server
Min Instances: 1              # Always warm (avoid cold starts)
Max Instances: 100            # Scale up to 100 instances
Concurrency: 80               # Max concurrent requests per instance
CPU: 2 vCPU                   # Per instance
Memory: 4 GiB                 # Per instance
Timeout: 300s                 # WebSocket connection timeout

Auto-Scaling Triggers:
  - Request Rate: Scale when request/sec > 60 per instance
  - CPU Utilization: Scale when CPU > 70%
  - Concurrent Connections: Scale when connections > 5000
  - Custom Metric: Active WebSocket connections

Scaling Characteristics:
  - Scale-up time: ~30 seconds (warm instances)
  - Scale-down time: ~5 minutes idle
  - Cold start time: ~2 seconds (Go binary)
```

**Advantages**:
- **Zero Infrastructure Management**: Google manages scaling, patching, availability
- **Pay-per-Use**: Only pay for request processing time
- **Global Load Balancing**: Automatic traffic distribution
- **Fast Scaling**: Instances spin up in seconds
- **Session Affinity**: Sticky sessions for WebSocket connections

### 8.2 WebSocket Session Affinity

**Problem**: WebSocket connections are stateful at transport layer

**GCP Solution**: Cloud Load Balancer with Session Affinity
```yaml
Load Balancer Configuration:
  Type: HTTPS Load Balancer (Global)
  Backend Service: Cloud Run (quiz-server)
  Session Affinity: 
    Type: Generated Cookie
    Cookie TTL: 3600 seconds (1 hour)
    Affinity: Client IP + Cookie
  
  WebSocket Support:
    Enabled: true
    Idle Timeout: 600 seconds (10 minutes)
    Backend Timeout: 600 seconds
  
  Health Check:
    Path: /health/ready
    Interval: 10 seconds
    Timeout: 5 seconds
    Healthy Threshold: 2
    Unhealthy Threshold: 3
```

**Failover Process**:
1. Instance failure detected by load balancer health check
2. Client WebSocket connection drops
3. Client reconnects (automatic retry with exponential backoff)
4. Load balancer routes to healthy instance
5. Server retrieves session state from Memorystore
6. Client resumes with minimal disruption (<2 seconds total)

### 8.3 Database Scaling (Cloud SQL)

**Write Path**:
- **Cloud SQL Proxy**: Connection pooling and secure access
- **Connection Pool**: 25 connections per Cloud Run instance
- **Async Writes**: Non-critical writes queued via Cloud Tasks
- **Write-Through Cache**: Memorystore for hot data

```yaml
Cloud SQL Configuration:
  Tier: db-custom-4-15360 (4 vCPU, 15 GB RAM)
  Storage: 100 GB SSD (auto-expand to 500 GB)
  Availability: Regional (automatic failover)
  
  Read Replicas:
    - Region: us-central1 (same as primary)
    - Lag: <1 second
    - Use Case: Analytics queries, reporting
  
  Connection Pooling:
    Max Connections: 500
    Per-Instance Limit: 25
    Idle Timeout: 300 seconds
```

**Read Path**:
- **Memorystore Cache**: >95% cache hit ratio target
- **Read Replicas**: Offload analytics and reporting queries
- **Query Optimization**: Prepared statements, indexes

**Partitioning Strategy**:
- Partition by `session_id` hash for horizontal sharding (future)
- Time-based partitioning for `answer_submissions` table
- Each partition handles subset of sessions

### 8.4 Memorystore Scaling

```yaml
Memorystore Configuration:
  Tier: Standard (HA with automatic failover)
  Current Capacity: 5 GB
  Scaling Path:
    - 5 GB: ~10K concurrent sessions
    - 20 GB: ~50K concurrent sessions
    - 100 GB: ~250K concurrent sessions
  
  Replica: Read replica (automatic)
  Persistence: RDB snapshots every 6 hours
  Eviction Policy: allkeys-lru
  Max Clients: 10,000 connections
```

**Scaling Triggers**:
- Memory usage > 80%: Increase capacity
- Operations/sec > 80K: Add read replicas or upgrade tier
- Connection count > 8K: Review connection pooling

### 8.5 Cloud Pub/Sub Scaling

**Capacity**:
- **Throughput**: Automatically scales to millions of messages/sec
- **Storage**: Up to 10 GB message retention per topic
- **Subscriptions**: 10,000 subscriptions per topic
- **Global**: Multi-region message distribution

**Performance**:
```yaml
Message Throughput:
  - Publishing: 100K messages/sec (per topic)
  - Delivery: 100K messages/sec (per subscription)
  - Latency: <100ms publish-to-delivery (same region)
  - Latency: <500ms publish-to-delivery (cross-region)

Scaling Configuration:
  - Auto-scaling: Enabled (default)
  - Partitions: Automatic based on load
  - Ordering: Optional per ordering key
```

### 8.6 Capacity Planning

**Target Load**:
- 10,000 concurrent WebSocket connections
- 100 active quiz sessions
- 100 participants per session average
- 10 answers/minute per participant
- Total: 100K answer submissions/hour

**Resource Estimates**:
```yaml
Cloud Run:
  Instances: 20-30 (at peak)
  Total vCPU: 40-60
  Total Memory: 80-120 GB
  Cost: ~$200-300/month (pay-per-use)

Cloud SQL:
  Instance: db-custom-4-15360
  Storage: 150 GB
  Cost: ~$350/month

Memorystore:
  Capacity: 20 GB (Standard tier)
  Cost: ~$150/month

Cloud Pub/Sub:
  Messages: 300M messages/month
  Cost: ~$120/month

Cloud Load Balancer:
  Forwarding Rules: 1
  Data Processed: 500 GB/month
  Cost: ~$50/month

Total Estimated Cost: ~$870/month (at target load)
```

### 8.7 Multi-Region Deployment (Future)

**Phase 1** (Current): Single Region (us-central1)
**Phase 2** (Future): Multi-Region for Global Users

```yaml
Regions:
  Primary: us-central1 (Iowa)
  Secondary: europe-west1 (Belgium)
  Tertiary: asia-northeast1 (Tokyo)

Deployment:
  - Cloud Run: Deployed to all 3 regions
  - Cloud Load Balancer: Global load balancing with geo-routing
  - Cloud SQL: Regional instances with cross-region replicas
  - Memorystore: Regional instances (no cross-region replication)
  - Pub/Sub: Global topics with regional subscriptions

Data Consistency:
  - Eventually consistent across regions
  - Strong consistency within region
  - Session affinity to nearest region
```

---

## 9. Performance Optimization

### 9.1 Latency Targets

| Operation | Target | P99 Target |
|-----------|--------|------------|
| Answer submission → Score update | <50ms | <100ms |
| Score update → Client notification | <50ms | <100ms |
| Leaderboard recalculation | <100ms | <200ms |
| User join | <100ms | <200ms |
| WebSocket message roundtrip | <20ms | <50ms |

### 9.2 Optimization Techniques

**1. Connection Pooling**
```go
// Database connection pool
maxOpenConns: 25 per instance
maxIdleConns: 10
connMaxLifetime: 5 minutes

// Redis connection pool
poolSize: 100 per instance
minIdleConns: 10
```

**2. Caching Strategy**
- L1: In-memory LRU cache (5-second TTL for quiz questions)
- L2: Redis cache (session state, leaderboards)
- L3: PostgreSQL (persistent storage)

**3. Message Batching**
- Leaderboard updates: 100ms batch window
- Metrics: 1-second aggregation
- Database writes: 500ms batch window

**4. Goroutine Pooling**
```go
// Worker pool for CPU-intensive tasks
workerPool: 100 workers per instance
taskQueue: buffered channel (capacity: 1000)
```

**5. Zero-Copy Message Passing**
- Use `sync.Pool` for message objects
- Reuse buffers for JSON serialization
- Minimize allocations in hot path

**6. Database Optimizations**
- Prepared statements for common queries
- Indexes on session_id, user_id, question_id
- Materialized views for leaderboard snapshots

### 9.3 Profiling & Benchmarking

**CPU Profiling**:
```bash
go test -cpuprofile=cpu.prof -bench=.
go tool pprof cpu.prof
```

**Memory Profiling**:
```bash
go test -memprofile=mem.prof -bench=.
go tool pprof mem.prof
```

**Load Testing**:
```javascript
// k6 script
export default function() {
  const ws = new WebSocket('ws://localhost:8080/ws?user_id=test');
  ws.on('open', () => {
    ws.send(JSON.stringify({type: 'JOIN_SESSION', payload: {session_id: 'test'}}));
  });
}
```

**Targets**:
- 10,000 concurrent WebSocket connections per instance
- <1% CPU at 1,000 connections
- <500MB memory at 10,000 connections
- 100K messages/second throughput

---

## 10. Reliability & Error Handling

### 10.1 Error Categories

**1. Client Errors (4xx equivalent)**
- Invalid session ID
- Malformed message
- Unauthorized access
- Rate limit exceeded

**Response**: Send ERROR message to client, log warning

**2. Server Errors (5xx equivalent)**
- Database connection failure
- Redis unavailable
- Internal processing error

**Response**: Send ERROR message, retry with exponential backoff, alert monitoring

**3. Network Errors**
- Connection dropped
- Timeout
- Packet loss

**Response**: Client reconnection logic, message replay

### 10.2 Error Handling Matrix

| Error Type | Detection | Response | Recovery | Client Impact |
|------------|-----------|----------|----------|---------------|
| Invalid session ID | Validation | ERROR message | None | User notified |
| Database timeout | Query timeout | Retry 3x, then ERROR | Cache fallback | Temporary degradation |
| Redis unavailable | Connection error | Use in-memory fallback | Auto-reconnect | Degraded real-time |
| WebSocket disconnect | Connection close | Cleanup resources | Client reconnect | Brief interruption |
| Message parse error | JSON unmarshal | ERROR response | Skip message | User notified |
| Rate limit | Request count | 429-style ERROR | Wait period | Temporary block |
| Score conflict | Optimistic lock | Retry with backoff | Resolve conflict | Transparent |

### 10.3 Fault Tolerance

**Circuit Breaker Pattern**:
```go
type CircuitBreaker struct {
    maxFailures  int           // 5 consecutive failures
    timeout      time.Duration // 30 seconds
    state        State         // Closed | Open | HalfOpen
}
```

**Graceful Degradation**:
- Redis unavailable → In-memory session state (single instance)
- Database unavailable → Cache-only mode (eventual consistency)
- High load → Throttle new connections, prioritize existing

**Retry Strategy**:
```go
// Exponential backoff
retries: 3
baseDelay: 100ms
maxDelay: 2s
backoff: baseDelay * 2^attempt
```

### 10.4 Data Consistency

**Consistency Model**: **Eventual Consistency** with **Strong Consistency** for scores

**Guarantees**:
- Scores: Strong consistency via atomic Redis operations
- Leaderboard: Eventual consistency (100ms delay acceptable)
- Session state: Eventual consistency across instances

**Conflict Resolution**:
- Last-write-wins for session metadata
- Atomic operations for scores (INCRBY)
- Optimistic locking for critical updates

---

## 11. Monitoring & Observability

### 11.1 Metrics (Prometheus)

**System Metrics**:
```
# Connections
websocket_active_connections{instance="server-1"}
websocket_total_connections{instance="server-1"}
websocket_connection_duration_seconds

# Sessions
quiz_active_sessions
quiz_total_participants
quiz_session_duration_seconds

# Performance
http_request_duration_seconds{endpoint="/ws"}
scoring_latency_seconds
leaderboard_update_latency_seconds

# Errors
error_total{type="client_error|server_error"}
connection_errors_total
database_errors_total

# Resources
go_goroutines
go_memstats_alloc_bytes
redis_connected_clients
postgresql_active_connections
```

**Business Metrics**:
```
quiz_answers_submitted_total
quiz_correct_answers_total
quiz_participants_joined_total
quiz_sessions_completed_total
```

### 11.2 Logging (Structured)

**Log Levels**:
- DEBUG: Detailed flow (disabled in production)
- INFO: Normal operations (user joined, answer submitted)
- WARN: Recoverable errors (invalid input, retries)
- ERROR: Serious errors (DB failure, unhandled exceptions)

**Log Format** (JSON):
```json
{
  "timestamp": "2025-11-16T10:30:00Z",
  "level": "INFO",
  "message": "User joined session",
  "user_id": "user-123",
  "session_id": "quiz-456",
  "trace_id": "abc-def-ghi",
  "latency_ms": 45
}
```

**Correlation**:
- Trace ID propagated through request chain
- User ID and Session ID in all relevant logs
- Request ID for debugging

### 11.3 Tracing (OpenTelemetry)

**Instrumentation Points**:
- WebSocket message handling (end-to-end)
- Database queries
- Redis operations
- Inter-service calls (Pub/Sub)

**Trace Example**:
```
Span 1: HandleWebSocketMessage (50ms)
  Span 2: ValidateSession (5ms)
  Span 3: ScoreEngine.SubmitAnswer (30ms)
    Span 4: Redis.INCRBY (2ms)
    Span 5: Database.InsertAnswer (20ms)
  Span 6: LeaderboardService.Update (10ms)
    Span 7: Redis.ZADD (2ms)
  Span 8: BroadcastUpdate (5ms)
```

### 11.4 Health Checks

**Liveness Probe**:
```
GET /health/live
Response: 200 if server is running
```

**Readiness Probe**:
```
GET /health/ready
Response: 200 if ready to accept traffic
Checks:
- Redis connection
- Database connection
- Memory usage < 90%
```

**Health Check Response**:
```json
{
  "status": "healthy",
  "checks": {
    "redis": {"status": "up", "latency_ms": 2},
    "database": {"status": "up", "latency_ms": 5},
    "memory": {"status": "ok", "usage_percent": 65}
  }
}
```

### 11.5 Alerting

**Critical Alerts** (PagerDuty):
- Error rate >1% for 5 minutes
- P99 latency >500ms for 5 minutes
- Database connection pool exhausted
- Redis unavailable

**Warning Alerts** (Slack):
- Error rate >0.5% for 10 minutes
- Memory usage >80%
- Connection count >8000 per instance
- Slow query detected (>1s)

---

## 12. Security Considerations (GCP-Native)

### 12.1 Network Security

**VPC and Private Services**:
```yaml
VPC Configuration:
  - VPC Name: quiz-app-vpc
  - Subnets: 
      - Cloud Run: Serverless VPC Access Connector
      - Cloud SQL: Private IP only (no public IP)
      - Memorystore: VPC-native (private IP)
  - Firewall Rules:
      - Deny all ingress by default
      - Allow HTTPS (443) from Cloud Load Balancer
      - Allow internal traffic between services
  - Private Google Access: Enabled
```

**Cloud Armor (DDoS Protection)**:
```yaml
Security Policies:
  - Rate Limiting:
      - 100 requests/minute per IP
      - 1000 requests/minute per user
  - Geographic Restrictions:
      - Allow: Global (configurable)
      - Block: Known malicious IPs (Google threat intelligence)
  - OWASP Top 10 Protection:
      - SQL Injection: Enabled
      - Cross-Site Scripting (XSS): Enabled
      - Layer 7 DDoS: Enabled
  - Bot Management:
      - Challenge suspicious traffic
      - Block known bad bots
```

**SSL/TLS**:
- **Google-Managed Certificates**: Automatic provisioning and renewal
- **TLS 1.3**: Enforced minimum version
- **HTTPS Only**: HTTP redirects to HTTPS
- **WebSocket Secure (WSS)**: Encrypted WebSocket connections

### 12.2 Identity and Access Management (IAM)

**Service Accounts** (Principle of Least Privilege):
```yaml
Service Accounts:
  quiz-server@project.iam.gserviceaccount.com:
    Roles:
      - Cloud SQL Client (cloudsql.client)
      - Pub/Sub Publisher (pubsub.publisher)
      - Pub/Sub Subscriber (pubsub.subscriber)
      - Secret Manager Secret Accessor (secretmanager.secretAccessor)
      - Logging Writer (logging.logWriter)
      - Monitoring Metric Writer (monitoring.metricWriter)
      - Cloud Trace Agent (cloudtrace.agent)
    Scope: Cloud Run service only
  
  cloud-build@project.iam.gserviceaccount.com:
    Roles:
      - Cloud Run Admin (run.admin)
      - Artifact Registry Writer (artifactregistry.writer)
      - Service Account User (iam.serviceAccountUser)
    Scope: Cloud Build only
  
  analytics@project.iam.gserviceaccount.com:
    Roles:
      - Cloud SQL Client (read-only)
      - BigQuery Data Editor (bigquery.dataEditor)
    Scope: Analytics pipeline only
```

**Workload Identity** (No Service Account Keys):
```yaml
# Cloud Run uses Workload Identity to access GCP services
# No JSON key files needed - automatic token exchange
Service: quiz-server
Service Account: quiz-server@project.iam.gserviceaccount.com
Workload Identity: Enabled
```

### 12.3 Secrets Management

**Secret Manager Integration**:
```go
import "cloud.google.com/go/secretmanager/apiv1"

// Access secrets at runtime (never in code or env vars)
func getSecret(ctx context.Context, secretName string) (string, error) {
    client, _ := secretmanager.NewClient(ctx)
    name := fmt.Sprintf("projects/%s/secrets/%s/versions/latest", projectID, secretName)
    result, _ := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{
        Name: name,
    })
    return string(result.Payload.Data), nil
}
```

**Secrets Stored in Secret Manager**:
```yaml
Secrets:
  - db-password          # Cloud SQL password
  - redis-auth-token     # Memorystore AUTH token (if enabled)
  - jwt-signing-key      # For user authentication tokens
  - api-keys             # Third-party API keys
  - encryption-key       # Data encryption key

Configuration:
  - Automatic Rotation: Enabled (90 days)
  - Version History: Last 10 versions retained
  - Access Audit: Cloud Audit Logs
  - Replication: Automatic (multi-region)
```

### 12.4 Input Validation and Sanitization

**WebSocket Messages**:
```go
// JSON schema validation
type SubmitAnswerPayload struct {
    SessionID  string `json:"session_id" validate:"required,uuid"`
    QuestionID string `json:"question_id" validate:"required,uuid"`
    Answer     string `json:"answer" validate:"required,max=1000"`
    TimeTaken  int    `json:"time_taken_ms" validate:"required,min=0,max=300000"`
}

// Validation
validator := validator.New()
err := validator.Struct(payload)

// Maximum message size: 10KB
const MaxMessageSize = 10 * 1024

// Rate limiting: 100 messages/second per user
// Implemented via Cloud Armor or application-level token bucket
```

**SQL Injection Prevention**:
```go
// Always use parameterized queries
stmt := `INSERT INTO participants (session_id, user_id, username) VALUES ($1, $2, $3)`
_, err := db.ExecContext(ctx, stmt, sessionID, userID, username)

// Use pgx for better prepared statement support
```

**XSS Prevention**:
- Sanitize all user inputs (usernames, answers)
- Use Content Security Policy (CSP) headers
- Encode output when rendering user-generated content

### 12.5 Authentication & Authorization

**Current Approach** (MVP - Simplified):
```go
// Simple user ID validation
// Production requires proper auth
userID := r.URL.Query().Get("user_id")
if !isValidUUID(userID) {
    return errors.New("invalid user ID")
}
```

**Production Approach** (Recommended):
```yaml
Authentication:
  Provider: Firebase Authentication or Identity Platform
  Methods:
    - Email/Password
    - Google OAuth
    - Social Logins (Facebook, Twitter)
  
  Token Validation:
    - JWT tokens with Cloud Endpoints
    - Token verification via Firebase Admin SDK
    - Short-lived tokens (1 hour)
    - Refresh token rotation

Authorization:
  - Role-based access control (RBAC)
  - Session ownership verification
  - Quiz access permissions
  - Admin vs participant roles
```

### 12.6 Data Protection

**Encryption**:
```yaml
Encryption at Rest:
  - Cloud SQL: Google-managed encryption (AES-256)
  - Memorystore: Google-managed encryption
  - Cloud Storage: Customer-managed encryption keys (CMEK) optional
  - Secret Manager: Automatic encryption

Encryption in Transit:
  - All traffic: TLS 1.3
  - Internal services: Automatic TLS (mTLS with service mesh)
  - Database connections: SSL/TLS enforced
```

**Data Retention & Privacy**:
```yaml
Data Classification:
  - Public: Quiz content, leaderboards
  - Internal: Session data, scores
  - Confidential: User emails, personal info (if collected)

Retention Policies:
  - Active Sessions: Duration + 24 hours
  - Completed Sessions: 90 days (configurable)
  - User Data: Account lifetime + 30 days after deletion
  - Audit Logs: 400 days (compliance requirement)
  - Access Logs: 30 days

GDPR Compliance:
  - Right to Access: Export user data API
  - Right to Erasure: User deletion workflow
  - Data Portability: JSON export
  - Consent Management: Cookie consent, ToS acceptance
```

### 12.7 Security Monitoring & Auditing

**Cloud Audit Logs**:
```yaml
Audit Log Types:
  - Admin Activity: All administrative actions (enabled by default)
  - Data Access: Database queries, secret access (enabled)
  - System Events: Service lifecycle events
  - Policy Denied: Failed authorization attempts

Log Retention: 400 days
Log Export: BigQuery for long-term analysis
```

**Security Command Center**:
- Vulnerability scanning for container images
- Misconfiguration detection
- Threat detection (anomalous activity)
- Compliance monitoring (CIS benchmarks)

**Anomaly Detection**:
```yaml
Alerts:
  - Unusual API access patterns
  - Failed authentication spike (>10 failures/minute)
  - Privilege escalation attempts
  - Data exfiltration indicators
  - Resource usage anomalies
  - Geographic anomalies (login from unexpected location)
```

### 12.8 Incident Response

**Security Incident Playbook**:
1. **Detection**: Security Command Center alert or Cloud Monitoring
2. **Isolation**: Revoke compromised service account, block IPs
3. **Investigation**: Review Cloud Audit Logs, analyze traffic
4. **Containment**: Deploy firewall rules, rotate secrets
5. **Recovery**: Restore from backups if needed
6. **Post-Mortem**: Document incident, update security policies

**Backup & Recovery**:
```yaml
Cloud SQL Backups:
  - Automated daily backups: Retained 7 days
  - On-demand backups: Before major changes
  - Point-in-time recovery: Up to 7 days
  - Cross-region backup: Enabled (disaster recovery)

Memorystore Backups:
  - RDB snapshots: Every 6 hours
  - Export to Cloud Storage: Daily
  - Retention: 7 days
```

---

## 14. Cost Optimization (GCP)

### 14.1 Cost Breakdown (Production)

```yaml
Monthly Cost Estimate (10K concurrent connections):

Cloud Run:
  - Instance Hours: 720 hours/month * 20 instances = 14,400 hours
  - vCPU: 14,400 hours * 2 vCPU * $0.00002400/vCPU-hour = $691
  - Memory: 14,400 hours * 4 GiB * $0.00000250/GiB-hour = $144
  - Requests: 100M requests * $0.40/million = $40
  - Subtotal: ~$875/month

Cloud SQL (PostgreSQL):
  - Instance: db-custom-4-15360 = $280/month
  - Storage: 150 GB SSD * $0.17/GB = $25.50/month
  - Backups: 150 GB * $0.08/GB = $12/month
  - Read Replica: $280/month (if enabled)
  - Subtotal: ~$317/month (without replica)

Memorystore for Redis:
  - Standard Tier: 20 GB * $0.054/GB-hour * 730 hours = $788/month
  - Subtotal: ~$788/month

Cloud Pub/Sub:
  - Message Throughput: 300M messages * $40/TB = ~$120/month
  - Subtotal: ~$120/month

Cloud Load Balancing:
  - Forwarding Rules: 1 * $18/month = $18/month
  - Data Processed: 500 GB * $0.008/GB = $4/month
  - Subtotal: ~$22/month

Cloud Logging:
  - Ingestion: 50 GB/month (first 50 GB free)
  - Storage: 100 GB * $0.01/GB = $1/month
  - Subtotal: ~$1/month

Cloud Monitoring:
  - Metrics: Included (first 150 MB/month free)
  - Subtotal: $0/month

Cloud Trace:
  - Traces: 10M spans/month (first 2.5M free) = $0.20/million * 7.5M = $1.50/month
  - Subtotal: ~$2/month

Total Estimated Cost: ~$2,125/month
```

### 14.2 Cost Optimization Strategies

**1. Cloud Run Optimizations**:
```yaml
Strategies:
  - Right-size instances: Monitor actual CPU/memory usage
  - Adjust min instances: Set to 1-2 instead of 0 to avoid cold starts
  - Optimize concurrency: Tune containerConcurrency based on load
  - Request batching: Batch Pub/Sub message processing
  - Connection pooling: Reuse database connections
  
Potential Savings: 20-30% ($175-260/month)
```

**2. Cloud SQL Optimizations**:
```yaml
Strategies:
  - Use connection pooling: Reduce instance size
  - Enable query insights: Identify and optimize slow queries
  - Implement caching: Reduce database load with Memorystore
  - Archive old data: Export to BigQuery for analytics
  - Scheduled scaling: Reduce size during off-peak hours
  
Potential Savings: 15-25% ($47-79/month)
```

**3. Memorystore Optimizations**:
```yaml
Strategies:
  - Monitor memory usage: Right-size capacity
  - Implement eviction policies: allkeys-lru to auto-remove old data
  - Data compression: Use Redis compression for large values
  - TTL optimization: Aggressive TTLs for session data
  - Basic tier for dev/staging: No replica needed
  
Potential Savings: 10-20% ($79-158/month)
```

**4. Committed Use Discounts**:
```yaml
Commitments (1-year):
  - Cloud Run: 37% discount on vCPU and memory
  - Cloud SQL: 30% discount on instance costs
  - Memorystore: 30% discount
  
Total Savings with Commitments: ~$600/month (28%)
Recommendation: Apply after 3 months of stable production usage
```

**5. Development Environment Auto-Shutdown**:
```yaml
Scheduled Scaling:
  - Weekdays: Scale up at 8 AM, down at 6 PM
  - Weekends: Keep minimal instances
  - Cloud Scheduler: Trigger scaling via Cloud Run API
  
Potential Savings: $100-150/month on dev environment
```

### 14.3 Budget Alerts

```yaml
Cloud Billing Budgets:
  Development:
    Budget: $100/month
    Alerts:
      - 50% threshold: Email to team
      - 90% threshold: Email to team lead
      - 100% threshold: Email + Slack + consider auto-shutdown
  
  Staging:
    Budget: $500/month
    Alerts:
      - 80% threshold: Email to team
      - 100% threshold: Email + Slack
  
  Production:
    Budget: $2,500/month
    Alerts:
      - 80% threshold: Email to team lead
      - 100% threshold: Email + PagerDuty
      - 120% threshold: Investigate anomaly
```

### 14.4 Cost Monitoring Dashboard

```yaml
Metrics to Track:
  - Cost per 1,000 requests
  - Cost per active user
  - Cost per quiz session
  - Cloud Run instance utilization (%)
  - Database connection pool usage (%)
  - Cache hit rate (%)
  - Pub/Sub message volume
  
Review Frequency:
  - Daily: Automated cost anomaly detection
  - Weekly: Team review of cost trends
  - Monthly: Management cost review and optimization planning
```

## 15. Implementation Planture (GCP Cloud Run)

### 13.1 Cloud Run Deployment

**Service Configuration**:
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: quiz-server
  namespace: default
  labels:
    app: quiz-server
    env: production
spec:
  template:
    metadata:
      annotations:
        # Auto-scaling
        autoscaling.knative.dev/minScale: "1"
        autoscaling.knative.dev/maxScale: "100"
        autoscaling.knative.dev/target: "80"
        
        # Networking
        run.googleapis.com/vpc-access-connector: quiz-vpc-connector
        run.googleapis.com/vpc-access-egress: private-ranges-only
        
        # Observability
        run.googleapis.com/execution-environment: gen2
        
    spec:
      serviceAccountName: quiz-server@project-id.iam.gserviceaccount.com
      containerConcurrency: 80
      timeoutSeconds: 300
      
      containers:
      - image: gcr.io/project-id/quiz-server:latest
        ports:
        - name: http1
          containerPort: 8080
        
        resources:
          limits:
            cpu: "2000m"
            memory: "4Gi"
        
        env:
        - name: ENV
          value: "production"
        - name: PROJECT_ID
          value: "project-id"
        - name: CLOUD_SQL_CONNECTION
          value: "project-id:us-central1:quiz-db"
        - name: REDIS_HOST
          valueFrom:
            secretKeyRef:
              name: redis-host
              key: host
        - name: REDIS_PORT
          value: "6379"
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 13.2 Infrastructure as Code (Terraform)

**Project Structure**:
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── cloud-run/
│   ├── cloud-sql/
│   ├── memorystore/
│   ├── pubsub/
│   ├── vpc/
│   └── monitoring/
└── backend.tf
```

**Example Module** (Cloud Run):
```hcl
# modules/cloud-run/main.tf
resource "google_cloud_run_service" "quiz_server" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.quiz_server.email
      container_concurrency = 80
      timeout_seconds = 300

      containers {
        image = var.container_image
        
        resources {
          limits = {
            cpu    = "2000m"
            memory = "4Gi"
          }
        }

        env {
          name  = "CLOUD_SQL_CONNECTION"
          value = google_sql_database_instance.quiz_db.connection_name
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "1"
        "autoscaling.knative.dev/maxScale" = "100"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.id
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.quiz_server.name
  location = google_cloud_run_service.quiz_server.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

### 13.3 Environment Strategy

**Development Environment**:
```yaml
Region: us-central1
Cloud Run:
  Min Instances: 0 (allow cold starts)
  Max Instances: 5
  CPU: 1 vCPU
  Memory: 2 GiB

Cloud SQL:
  Tier: db-f1-micro
  Storage: 10 GB
  High Availability: Disabled
  Backups: 3 days retention

Memorystore:
  Tier: Basic (no replica)
  Capacity: 1 GB

Cost: ~$50/month
```

**Staging Environment**:
```yaml
Region: us-central1
Cloud Run:
  Min Instances: 1
  Max Instances: 20
  CPU: 2 vCPU
  Memory: 4 GiB

Cloud SQL:
  Tier: db-custom-2-7680
  Storage: 50 GB
  High Availability: Enabled
  Backups: 7 days retention

Memorystore:
  Tier: Standard (with replica)
  Capacity: 5 GB

Cost: ~$400/month
```

**Production Environment**:
```yaml
Region: us-central1 (multi-region future)
Cloud Run:
  Min Instances: 2 (always warm)
  Max Instances: 100
  CPU: 2 vCPU
  Memory: 4 GiB

Cloud SQL:
  Tier: db-custom-4-15360
  Storage: 150 GB (auto-expand)
  High Availability: Enabled
  Backups: 30 days retention
  Read Replicas: 1

Memorystore:
  Tier: Standard (with replica)
  Capacity: 20 GB

Cloud Pub/Sub:
  Topics: 5
  Subscriptions: 10

Cost: ~$900/month
```

### 13.4 Deployment Pipeline

**CI/CD Flow** (Cloud Build):
```
1. Code Push to main branch
   ↓
2. Cloud Build Trigger
   ↓
3. Run Tests (unit + integration)
   ↓
4. Build Docker Image
   ↓
5. Push to Artifact Registry
   ↓
6. Container Vulnerability Scan
   ↓
7. Deploy to Staging (auto)
   ↓
8. Run Smoke Tests
   ↓
9. Await Manual Approval
   ↓
10. Deploy to Production
   ↓
11. Run Health Checks
   ↓
12. Gradual Traffic Shift (0% → 100%)
   ↓
13. Monitor Metrics
   ↓
14. Rollback if errors detected
```

**Blue-Green Deployment**:
```yaml
# Deploy new revision without traffic
gcloud run deploy quiz-server \
  --image=gcr.io/project-id/quiz-server:v2 \
  --no-traffic \
  --tag=blue

# Test blue revision
curl https://blue---quiz-server-xxx.run.app/health

# Shift traffic gradually
gcloud run services update-traffic quiz-server \
  --to-revisions=quiz-server-v2=25  # 25% traffic

# Monitor metrics, then increase
gcloud run services update-traffic quiz-server \
  --to-revisions=quiz-server-v2=100  # 100% traffic

# Rollback if needed
gcloud run services update-traffic quiz-server \
  --to-revisions=quiz-server-v1=100
```

### 13.5 Configuration Management

**Environment Variables** (Cloud Run):
```yaml
Runtime Environment Variables:
  ENV: production|staging|development
  PROJECT_ID: gcp-project-id
  REGION: us-central1
  LOG_LEVEL: info|debug|warn|error
  
Service Connections:
  CLOUD_SQL_CONNECTION: project:region:instance
  REDIS_HOST: 10.x.x.x
  REDIS_PORT: 6379
  
Feature Flags:
  ENABLE_ANALYTICS: true|false
  ENABLE_RATE_LIMITING: true|false
  MAX_CONNECTIONS_PER_INSTANCE: 5000
```

**Secrets** (Secret Manager):
- Never in environment variables
- Accessed at runtime via Secret Manager API
- Automatic rotation policies
- Audit logging for access

### 13.6 Disaster Recovery

**Backup Strategy**:
```yaml
Cloud SQL:
  - Automated Backups: Daily at 03:00 UTC
  - Retention: 30 days
  - Point-in-time Recovery: 7 days
  - Cross-region Backup: Enabled (us-east1)
  - Export to Cloud Storage: Weekly (for long-term retention)

Memorystore:
  - RDB Snapshots: Every 6 hours
  - Export to Cloud Storage: Daily
  - Retention: 7 days

Application Data:
  - Answer Submissions: Exported to BigQuery daily
  - Session Logs: Cloud Logging with 400-day retention
```

**Recovery Objectives**:
```yaml
RTO (Recovery Time Objective): 1 hour
RPO (Recovery Point Objective): 5 minutes

Disaster Scenarios:
  Regional Outage:
    - Manual failover to backup region
    - DNS update to route traffic
    - Estimated recovery: 30 minutes
  
  Data Corruption:
    - Restore from Cloud SQL backup
    - Point-in-time recovery
    - Estimated recovery: 15 minutes
  
  Application Bug:
    - Rollback to previous Cloud Run revision
    - Estimated recovery: 2 minutes
```

**Runbooks**:
1. Database restoration procedure
2. Cross-region failover procedure
3. Application rollback procedure
4. Security incident response
5. Performance degradation troubleshooting

### 13.1 Phase 1: Foundation (MVP)

**Goal**: Basic real-time quiz server with core functionality

**Tasks**:
1. Project setup (Go modules, directory structure)
2. WebSocket server implementation
3. Basic message handling (JOIN, SUBMIT_ANSWER)
4. In-memory session management
5. Simple scoring engine
6. Basic leaderboard (in-memory)
7. Mock client for testing

**Deliverable**: Working server handling 100 concurrent users

**Timeline**: 2-3 days

### 13.2 Phase 2: Persistence & Scaling

**Goal**: Add Redis/PostgreSQL, support multiple instances

**Tasks**:
1. Redis integration (sessions, leaderboard)
2. PostgreSQL schema and integration
3. Pub/Sub for cross-instance messaging
4. Connection manager refactoring
5. Database repositories
6. Atomic score updates

**Deliverable**: Scalable server with persistent state

**Timeline**: 2-3 days

### 13.3 Phase 3: Observability & Reliability

**Goal**: Production-ready monitoring and error handling

**Tasks**:
1. Prometheus metrics integration
2. Structured logging (Zap)
3. Health check endpoints
4. Error handling and recovery
5. Circuit breakers
6. Graceful shutdown

**Deliverable**: Observable, resilient server

**Timeline**: 1-2 days

### 13.4 Phase 4: Testing & Documentation

**Goal**: Comprehensive testing and documentation

**Tasks**:
1. Unit tests (>80% coverage)
2. Integration tests (Redis, PostgreSQL)
3. Load testing (k6 scripts)
4. API documentation
5. Deployment guide (Docker Compose)
6. Performance benchmarking

**Deliverable**: Fully tested and documented system

**Timeline**: 2-3 days

### 13.5 AI Collaboration Strategy

**AI Tool Usage**:

1. **GitHub Copilot** (Primary):
   - Code generation for boilerplate (struct definitions, interfaces)
   - Test case generation
   - Documentation comments

2. **Claude AI** (Secondary):
   - Architecture review and feedback
   - Algorithm optimization suggestions
   - Error handling patterns

3. **ChatGPT** (Tertiary):
   - Debugging assistance
   - Performance optimization ideas
   - Documentation review

**Verification Process**:
- All AI-generated code reviewed line-by-line
- Unit tests for all generated functions
- Integration tests for critical paths
- Manual testing for WebSocket flows
- Code linting and static analysis
- Performance profiling for hot paths

**Documentation**:
- Code comments marking AI-assisted sections
- Separate AI_COLLABORATION.md file
- Prompts and responses logged
- Verification steps documented

---

## Decision Records

### Decision 1 - November 16, 2025
**Decision**: Implement server component (not client)
**Context**: Challenge requires implementing one core component
**Options**: 
  - Server: More complex, demonstrates concurrency, scalability
  - Client: Simpler, UI-focused, less engineering depth
**Rationale**: Server showcases backend engineering skills better, handles real-time complexity, and is more aligned with system design requirements
**Impact**: Focus development on Go server, mock clients for testing
**Review**: N/A (core design decision)

### Decision 2 - November 16, 2025
**Decision**: Use Go (Golang) for server implementation
**Context**: Need high-performance language for real-time WebSocket handling
**Options**:
  - Go: Great concurrency, performance, simple deployment
  - Node.js: Good for WebSockets, but less performant
  - Java/Spring: Enterprise-grade, but more complex
**Rationale**: Go's goroutines and channels are ideal for concurrent WebSocket connections; compiled binary simplifies deployment; strong real-time system track record
**Impact**: Use gorilla/websocket, gin framework, native concurrency
**Review**: After load testing (if performance issues arise)

### Decision 3 - November 16, 2025
**Decision**: Use Redis for state management and leaderboard
**Context**: Need fast, scalable state storage for real-time updates
**Options**:
  - Redis: In-memory, sorted sets for leaderboard, pub/sub
  - PostgreSQL only: Simpler, but slower for real-time
  - In-memory only: Fast, but not scalable
**Rationale**: Redis sorted sets (ZADD, ZRANGE) are perfect for leaderboards; pub/sub enables cross-instance messaging; atomic operations ensure score consistency
**Impact**: Add Redis dependency, implement caching layer
**Review**: If scale exceeds Redis capacity (~50K ops/sec)

### Decision 4 - November 16, 2025
**Decision**: Batch leaderboard updates (100ms window)
**Context**: Frequent score updates could overwhelm clients with messages
**Options**:
  - Real-time (every score change): Most responsive, but high traffic
  - Batched (100ms): Balanced, reduces traffic 10-100x
  - Polling (1s): Lowest traffic, but noticeable lag
**Rationale**: 100ms delay is imperceptible to users; dramatically reduces message volume; allows aggregating multiple score changes
**Impact**: Implement batching logic in leaderboard service
**Review**: Adjust batch window based on user testing

### Decision 5 - November 16, 2025
**Decision**: Eventual consistency for leaderboard, strong consistency for scores
**Context**: Need to balance consistency with performance
**Options**:
  - Strong consistency everywhere: Accurate, but slow
  - Eventual everywhere: Fast, but confusing for users
  - Hybrid: Score strong, leaderboard eventual
**Rationale**: Users care most about their own score (must be accurate); leaderboard ranking delays of <200ms are acceptable; allows performance optimization
**Impact**: Use atomic Redis operations for scores, accept propagation delay for rankings
**Review**: Monitor user feedback on ranking accuracy

---

## Next Steps

1. ✅ Requirements analysis complete (`requirements.md`)
2. ✅ System design complete (`design.md`)
3. ⏭️ Create detailed implementation tasks (`tasks.md`)
4. ⏭️ Begin Phase 1 implementation
5. ⏭️ Set up development environment (Go, Redis, PostgreSQL)
6. ⏭️ Implement WebSocket server foundation

---

**Document Version**: 1.0  
**Authors**: AI-Assisted Design (Claude AI + Human Review)  
**Status**: Ready for Implementation
