# VanGo - Sprint 3: Backend Funcional Completo

## O que mudou
Esta sprint transforma o app de UI-only para um MVP funcional com Firebase + APIs gratuitas.

## Novos Pacotes (adicionar no pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.3
  cloud_firestore: ^5.6.6
  http: ^1.6.0
  uuid: ^4.2.1
  get_it: ^7.6.4
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^13.0.2
```

## Permissões Necessárias

### Android (android/app/src/main/AndroidManifest.xml)
Adicione ANTES do `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (ios/Runner/Info.plist)
Adicione dentro de `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>VanGo precisa da sua localização para compartilhar com os alunos durante a rota.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>VanGo precisa da localização em segundo plano para manter o compartilhamento ativo durante a rota.</string>
```

## Como Instalar
1. Substitua a pasta `lib/` inteira pelo conteúdo deste zip
2. Atualize o `pubspec.yaml` com os pacotes acima
3. Rode `flutter pub get`
4. Adicione as permissões de localização
5. Rode `flutter run`

## Funcionalidades Implementadas

### Estudante
- **Chamada diária** → Vota ida+volta, só ida, só volta ou não vai. Salva no Firestore em `salas/{salaId}/attendance/{data}/votes/{userId}`
- **Confirmação ao mudar voto** → Se já votou, pergunta "tem certeza?"
- **Botão Liberado** → Sempre habilitado (sem restrição de horário). Salva `liberado: true` no Firestore
- **Mapa da Van** → flutter_map + OpenStreetMap mostra localização do motorista em tempo real
- **Tela de setup** → Se sem sala, mostra card bonito pra entrar (sem tela preta)

### Motorista
- **Dashboard com dados reais** → Streams do Firestore: total alunos, confirmados, pendentes, liberados
- **Lista de liberações** → Aparece em tempo real quando aluno marca liberado
- **Chamada completa** → Tabs Todos/Ida/Volta/Liberados com dados do Firestore
- **Lista de alunos** → Stream real com filtros funcionando
- **Cadastro de Faculdade com CEP** → ViaCEP preenche endereço + Nominatim geocodifica lat/lng automaticamente
- **Montar Rota** → Carrega alunos confirmados + faculdades do Firestore. Cards arrastáveis (drag-and-drop)
- **Otimização OSRM** → Botão "Otimizar" chama OSRM /trip (TSP). Mostra distância/tempo economizados. Pergunta se aceita
- **Navegação ativa (estilo Waze)** → flutter_map com rota desenhada (polyline), marcadores das paradas, posição GPS em tempo real
- **Compartilhamento de localização** → GPS via geolocator, atualiza Firestore a cada 10s

### Geral
- **Telefone no cadastro** → Campo novo na página de registro
- **Geocoding no cadastro** → Lat/lng são salvos automaticamente quando o usuário se cadastra (Nominatim)
- **Esqueci minha senha** → Link na tela de login, envia email via Firebase Auth
- **Navegação segura** → Shell sempre acessível, sem tela preta

## Estrutura Firestore
```
users/{userId}
  - id, name, email, phone, role, salaId, salaIds[]
  - logradouro, numero, complemento, bairro, cep, localidade, uf
  - latitude, longitude, faculdadeId, faculdadeName

salas/{salaId}
  - id, name, accessCode, driverId, driverName

salas/{salaId}/students/{userId}
  - userId, name, joinedAt

salas/{salaId}/faculdades/{facId}
  - id, name, address, latitude, longitude

salas/{salaId}/attendance/{YYYY-MM-DD}/votes/{userId}
  - status (vaiEVolta|soIda|soVolta|naoVai)
  - liberado (bool), liberadoAt
  - userName, faculdadeId, faculdadeName, updatedAt

salas/{salaId}/driverLocation/current
  - latitude, longitude, isSharing, timestamp
```

## APIs Utilizadas (todas gratuitas)
- **OpenStreetMap** - Tiles do mapa (flutter_map)
- **OSRM** - Cálculo de rotas e otimização TSP (router.project-osrm.org)
- **Nominatim** - Geocoding/reverse geocoding (nominatim.openstreetmap.org)
- **ViaCEP** - Busca de endereço por CEP (viacep.com.br)
- **Firebase Spark** - Auth + Firestore (plano gratuito)

## Pendências para próxima iteração
- Notificações locais (flutter_local_notifications) - precisa setup nativo
- Múltiplas salas UI (seletor no perfil) - modelo de dados já suporta
- Múltiplos endereços estilo iFood - modelo precisa ser expandido
- Recálculo dinâmico de rota quando aluno é liberado
- Ícones coloridos dos alunos nas faculdades no mapa
- Som de notificação quando aluno é liberado
