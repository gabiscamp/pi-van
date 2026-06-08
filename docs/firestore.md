# Estrutura do Firestore — VanGo

> Projeto: `app-de-van-5f05d`

---

## Coleções e documentos

### `users/{userId}`

Documento do usuário criado no cadastro. Atualizado quando o usuário troca de sala ou faculdade.

```json
{
  "id": "uid_firebase",
  "name": "Maria Silva",
  "email": "maria@email.com",
  "phone": "(31) 99999-9999",
  "role": "estudante",
  "salaId": "sala_abc123",
  "salaIds": ["sala_abc123", "sala_xyz456"],
  "logradouro": "Rua das Flores",
  "numero": "42",
  "complemento": "Apto 3",
  "bairro": "Centro",
  "cep": "30110-000",
  "localidade": "Belo Horizonte",
  "uf": "MG",
  "latitude": -19.9167,
  "longitude": -43.9345,
  "faculdadeId": "fac_001",
  "faculdadeName": "Senac BH"
}
```

#### `users/{userId}/addresses/{addressId}` (subcoleção)

Endereços salvos pelo aluno. Criado automaticamente no cadastro com label "Casa".

```json
{
  "id": "addr_uuid",
  "label": "Casa",
  "logradouro": "Rua das Flores",
  "numero": "42",
  "complemento": "Apto 3",
  "bairro": "Centro",
  "cep": "30110-000",
  "localidade": "Belo Horizonte",
  "uf": "MG",
  "latitude": -19.9167,
  "longitude": -43.9345,
  "isDefault": true
}
```

---

### `salas/{salaId}`

Sala criada pelo motorista. O `accessCode` é o código que o aluno digita para entrar.

```json
{
  "id": "sala_abc123",
  "name": "Van Manhã",
  "accessCode": "ABC123",
  "driverId": "uid_motorista",
  "driverName": "João Motorista"
}
```

#### `salas/{salaId}/students/{userId}` (subcoleção)

Alunos membros da sala. Atualizado quando o aluno seleciona sua faculdade.

```json
{
  "userId": "uid_estudante",
  "name": "Maria Silva",
  "joinedAt": "Timestamp",
  "faculdadeId": "fac_001",
  "faculdadeName": "Senac BH",
  "lastProximityNotifAt": "Timestamp"
}
```

#### `salas/{salaId}/faculdades/{faculdadeId}` (subcoleção)

Faculdades cadastradas pelo motorista via CEP.

```json
{
  "id": "fac_001",
  "name": "Senac BH",
  "address": "Rua Albita, 61, Cruzeiro, Belo Horizonte - MG",
  "latitude": -19.9456,
  "longitude": -43.9337
}
```

#### `salas/{salaId}/attendance/{date}/votes/{userId}` (subcoleção)

Voto de chamada do aluno para o dia. `date` formato `YYYY-MM-DD`.

```json
{
  "status": "vaiEVolta",
  "userName": "Maria Silva",
  "faculdadeId": "fac_001",
  "faculdadeName": "Senac BH",
  "updatedAt": "2026-06-08T09:00:00.000Z",
  "liberado": true,
  "liberadoAt": "2026-06-08T17:30:00.000Z",
  "boarding": {
    "addressId": "addr_uuid",
    "label": "Casa",
    "shortAddress": "Rua das Flores, 42",
    "latitude": -19.9167,
    "longitude": -43.9345
  },
  "dropoff": {
    "addressId": "addr_uuid",
    "label": "Casa",
    "shortAddress": "Rua das Flores, 42",
    "latitude": -19.9167,
    "longitude": -43.9345
  }
}
```

**Valores de `status`:**
| Valor | Significado |
|---|---|
| `pendente` | Ainda não respondeu |
| `vaiEVolta` | Vai e volta |
| `soIda` | Só vai |
| `soVolta` | Só volta |
| `naoVai` | Não vai hoje |

#### `salas/{salaId}/driverLocation/current` (documento único)

Localização do motorista atualizada a cada 10 segundos durante a rota.

```json
{
  "latitude": -19.9200,
  "longitude": -43.9400,
  "isSharing": true,
  "timestamp": "Timestamp"
}
```

---

## Regras de segurança (Firestore Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuário lê/escreve seu próprio documento
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;

      match /addresses/{addressId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Salas: motorista tem controle total, aluno pode ler
    match /salas/{salaId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;

      match /students/{studentId} {
        allow read, write: if request.auth != null;
      }

      match /faculdades/{facId} {
        allow read, write: if request.auth != null;
      }

      match /attendance/{date}/votes/{userId} {
        allow read, write: if request.auth != null;
      }

      match /driverLocation/{doc} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

> **Nota:** As regras acima são permissivas para facilitar o desenvolvimento do MVP. Em produção, deveriam ser refinadas para validar papéis (motorista vs estudante).
