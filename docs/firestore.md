# Firestore structure (draft)

## Collections

### users/{userId}

```json
{
  "id": "uid",
  "name": "Maria",
  "email": "maria@email.com",
  "role": "motorista",
  "salaId": "sala_001"
}
```

### salas/{salaId}

```json
{
  "id": "sala_001",
  "name": "Van Manha",
  "accessCode": "ABC123",
  "driverId": "uid_motorista"
}
```

### salas/{salaId}/students/{userId}

```json
{
  "userId": "uid_estudante",
  "name": "Joao",
  "status": "confirmed" 
}
```

## Security rules (high level)

- Users can read/write their own user doc.
- Only drivers can create/update their sala.
- Students can join a sala only with a valid accessCode.
- Students can read their own membership doc inside a sala.

These rules will be refined when Firebase is wired.
