# IoT Smart Home Platform for Raspberry Pi
## Technical Design and Implementation Report

### 1. Executive Summary

This project implements an intelligent Smart Home Control Platform deployed on Raspberry Pi, providing a unified RESTful API for environmental monitoring, device control, automated safety response, and AI-driven voice interaction.

The system integrates multiple hardware modules including environmental sensors, gas detection, lighting control, door automation mechanisms, LCD display, audible alarms, and an embedded AI pipeline consisting of Speech-to-Text (STT), Large Language Model (LLM) processing, and Text-to-Speech (TTS).

The architecture follows a layered design pattern separating presentation, business logic, hardware abstraction, and AI processing components to improve maintainability, scalability, and hardware portability.

---

# 2. System Objectives

## Functional Objectives

- Real-time environmental monitoring.
- Smart lighting control by room.
- Automated front and rear door control.
- Garage door operation through stepper motor.
- Main entrance control through DC motor and L298N driver.
- Gas leak detection and alarm activation.
- LCD-based status visualization.
- Voice-controlled smart home interaction.
- Natural language command processing using AI.

## Non-Functional Objectives

- Modular architecture.
- Hardware abstraction.
- Low resource consumption.
- High maintainability.
- Extensible API design.
- Raspberry Pi compatibility.

---

# 3. Technology Stack

| Category | Technology |
|-----------|-----------|
| Language | Python 3.x |
| Web Framework | FastAPI |
| ASGI Server | Uvicorn |
| GPIO Control | gpiozero, RPi.GPIO |
| Sensor Library | adafruit_dht |
| LCD Driver | RPLCD |
| AI Speech Recognition | Faster-Whisper |
| Large Language Model | Qwen 2.5 GGUF |
| LLM Runtime | llama-cpp-python |
| Text-To-Speech | Edge TTS |
| Async File Handling | aiofiles |
| Data Validation | Pydantic |
| Hardware Platform | Raspberry Pi 4 Model B |

---

# 4. System Architecture

## Layered Architecture

```text
Client Applications
        │
        ▼
 REST API Layer
        │
        ▼
 Route Layer
        │
        ▼
 Manager Layer
        │
        ▼
 Service Layer
        │
        ▼
 Hardware / AI Components
```

### Route Layer

Responsible for:

- HTTP endpoint exposure
- Request validation
- Response formatting
- Exception propagation

### Manager Layer

Responsible for:

- Business logic
- State validation
- Command orchestration
- Hardware coordination

### Service Layer

Responsible for:

- Direct GPIO interaction
- Hardware abstraction
- Device state management
- Low-level motor control

---

# 5. Project Structure

```text
app/
├── main.py
├── routes/
├── managers/
├── services/
├── models/
├── temp_audio/
└── README.md
```

## Routes

| Module | Responsibility |
|----------|---------------|
| api_route.py | Router aggregation |
| dht_route.py | DHT11 APIs |
| gas_route.py | Gas APIs |
| led_route.py | Lighting APIs |
| servo_route.py | Servo door APIs |
| stepper_route.py | Garage APIs |
| dc_motor_route.py | Main door APIs |
| ai_route.py | Voice AI APIs |

## Managers

| Module | Responsibility |
|----------|---------------|
| dht_manager.py | Sensor management |
| gas_manager.py | Gas processing |
| led_manager.py | Lighting logic |
| servo_manager.py | Door validation |
| stepper_manager.py | Garage workflow |
| dc_motor_manager.py | Main door workflow |

## Services

| Module | Responsibility |
|----------|---------------|
| sensor_service.py | DHT11 access |
| gas_service.py | Gas sensor access |
| device_service.py | LED management |
| servo_service.py | Servo control |
| stepper_service.py | Stepper control |
| motor_dc_service.py | DC motor control |
| lcd_service.py | LCD communication |
| buzzer_service.py | Alarm generation |
| task_manager.py | Background services |

---

# 6. Hardware Subsystems

## Environmental Monitoring

### DHT11 Sensor

Collected data:

- Temperature
- Humidity

Features:

- Periodic sampling
- LCD display integration
- API exposure

---

## Gas Detection System

Capabilities:

- Leak detection
- Continuous monitoring
- Automatic alarm triggering

Alarm mechanism:

1. Gas detected.
2. Buzzer activated.
3. LCD updated.
4. API status changed.

---

## Smart Lighting System

Features:

- Multi-room support.
- Independent control.
- Real-time status tracking.
- Voice command integration.

---

## Servo Door Control

Purpose:

- Front door control.
- Rear door control.

Operations:

- Open
- Close
- Status monitoring

---

## Garage Door System

Hardware:

- Stepper Motor

Capabilities:

- Controlled rotation count.
- Open/close operations.
- State protection.
- Background execution.

States:

```text
closed
opening
open
closing
stopped
```

---

## Main Entrance DC Motor System

### Overview

A dedicated DC motor subsystem has been integrated for controlling the primary entrance mechanism.

### Hardware Configuration

Motor Driver:

- L298N

Control Pins:

| Signal | Purpose |
|----------|----------|
| ENB | Motor Enable |
| IN3 | Direction Control |
| IN4 | Direction Control |

### Software Component

Service:

```text
motor_dc_service.py
```

Manager:

```text
dc_motor_manager.py
```

API:

```text
dc_motor_route.py
```

### State Model

```text
closed
opening
open
closing
unknown
```

### Operational Flow

Opening Sequence:

1. Enable motor driver.
2. Set IN3 HIGH.
3. Set IN4 LOW.
4. Run motor for calibrated duration.
5. Stop power output.
6. Update state to OPEN.

Closing Sequence:

1. Enable motor driver.
2. Set IN3 LOW.
3. Set IN4 HIGH.
4. Run motor for calibrated duration.
5. Stop power output.
6. Update state to CLOSED.

### Concurrency Protection

The subsystem uses:

```python
asyncio.Lock()
```

to prevent simultaneous motor commands and race conditions.

---

# 7. AI Voice Processing Pipeline

## Processing Flow

```text
Voice Input
    │
    ▼
 Faster Whisper
    │
    ▼
 Transcribed Text
    │
    ▼
 Qwen 2.5 LLM
    │
    ▼
 Intent Extraction
    │
    ▼
 Hardware Execution
    │
    ▼
 Edge TTS
    │
    ▼
 Audio Response
```

## Speech Recognition

Engine:

- Faster Whisper

Responsibilities:

- Audio transcription
- Vietnamese speech processing
- Offline execution

---

## Natural Language Understanding

Model:

- Qwen 2.5 GGUF

Responsibilities:

- Intent detection
- Entity extraction
- Action mapping
- Smart response generation

---

## Speech Synthesis

Engine:

- Microsoft Edge TTS

Responsibilities:

- Audio generation
- Human-readable responses

---

# 8. REST API Specification

## Sensor APIs

```http
GET /dht
GET /gas
```

## Lighting APIs

```http
GET  /led
POST /led/{room}
```

## Servo APIs

```http
GET  /servo/{door}
POST /servo/{door}/open
POST /servo/{door}/close
```

## Garage APIs

```http
GET  /stepper/status
POST /stepper/control
POST /stepper/reset
```

## DC Motor APIs

```http
GET  /motor/status
POST /motor/open
POST /motor/close
```

## AI APIs

```http
POST /ai/process-voice
GET  /ai/download-response-audio
```

---

# 9. Background Services

## LCD Update Service

Periodically displays:

- Temperature
- Humidity
- System status

## Gas Monitoring Service

Continuously:

- Reads gas sensor
- Evaluates threshold
- Triggers buzzer

---

# 10. Reliability and Safety Considerations

Implemented safeguards:

- Hardware abstraction layer
- Exception handling
- Device state validation
- Concurrency protection
- Automatic motor shutdown
- GPIO cleanup mechanisms

Recommended future improvements:

- JWT authentication
- HTTPS deployment
- MQTT integration
- Home Assistant integration
- Database persistence
- Docker deployment
- Monitoring dashboard

---

# 11. Deployment

## Install Dependencies

```bash
pip install -r requirements.txt
```

## Start Application

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## API Documentation

```text
http://<raspberry-pi-ip>:8000/docs
```

---

# 12. Conclusion

The platform demonstrates a complete edge-based Smart Home architecture combining IoT hardware control, environmental monitoring, safety automation, and embedded AI capabilities.

The addition of the DC Motor Control Subsystem extends the system's physical access-control capabilities and provides a dedicated, asynchronous, state-managed mechanism for operating the main entrance. Together with the existing servo and stepper modules, the platform now supports multiple categories of motorized automation while maintaining a unified API and software architecture.
