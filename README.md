# Ciclou - Coleta de Óleo Sustentável

Um aplicativo **Flutter** que promove a sustentabilidade ao conectar quem deseja descartar óleo de cozinha usado com coletores autorizados. O objetivo é **facilitar e incentivar** o descarte correto, evitando danos ao meio ambiente.

---

## :sparkles: Visão Geral

- **Conectar usuários**: Pessoas que têm óleo usado podem se cadastrar e solicitar a coleta.
- **Coletores autorizados**: Empresas ou profissionais especializados se cadastram como coletores para receber solicitações.
- **Transparência**: Permitir que ambas as partes acompanhem o status da coleta em tempo real.

---

## :camera_flash: Capturas de Tela

![Telas](./assets/ciclou_telas.png)

---

## :wrench: Tecnologias Utilizadas

- **Flutter** (Dart)
- **Firebase**
  - Authentication
  - Firestore
  - Dynamic Links
  - Functions
  - Storage

---

## :inbox_tray: Instalação e Execução

### 1. Pré-Requisitos

- [**Flutter SDK**](https://docs.flutter.dev/get-started/install) instalado
- **Dart** instalado
- **Android Studio ou VSCode** com plugins Flutter/Dart configurados
- **Emulador Android/iOS** ou dispositivo físico para testes

### 2. Clonar o repositório

```bash
git clone https://github.com/LucasBatista37/ciclou_projeto.git
````

### 3. Instalar dependências

```bash
flutter pub get
```

### 4. Configurar o Firebase (Android)

1.  **Crie um projeto** no [Firebase Console](https://console.firebase.google.com/).
2.  **Adicione um app Android** ao projeto, usando o mesmo _Package Name_ do seu arquivo `AndroidManifest.xml` (por exemplo: `com.example.ciclou`).
3.  **Baixe** o arquivo `google-services.json` e **coloque** em `android/app/`.
4.  **Adicione** ou verifique se o `build.gradle` (dentro de `android/build.gradle`) tem a linha:

    ```gradle
    plugins {  
     // ...  
    
     // Add the dependency for the Google services Gradle plugin
     id 'com.google.gms.google-services' version '4.4.2' apply false
    }

    ```

5.  **No `app/build.gradle`**, adicione no final:

    ```gradle
    
    plugins {  
     id 'com.android.application'
     // Add the Google services Gradle plugin  
     id 'com.google.gms.google-services'
     ...
    }
     
     dependencies {  
     // Import the Firebase BoM
     implementation platform('com.google.firebase:firebase-bom:33.10.0')
     
     // TODO: Add the dependencies for Firebase products you want to use  
     // When using the BoM, don't specify versions in Firebase dependencies
     implementation 'com.google.firebase:firebase-analytics'
     
     // Add the dependencies for any other desired Firebase products  
     // https://firebase.google.com/docs/android/setup#available-libraries
     }

6.  Verifique se o seu arquivo `.gitignore` inclui:

    ```gitignore
    google-services.json
    ```


> **Obs**: Para iOS, baixe o `GoogleService-Info.plist` e coloque em `ios/Runner/`.

### 5. Executar o projeto

```bash
flutter run
```

_(Escolha o dispositivo/emulador compatível.)_

---

## :sparkles: Funcionalidades Principais

1.  **Cadastro e Login**
    -   **Usuário comum**: quem tem óleo para descartar.
    -   **Coletor**: responsável por recolher o óleo.
2.  **Solicitação de Coleta**
    -   O usuário informa **quantidade de óleo**, **endereço**, **horário** preferencial e demais dados para coleta.
3.  **Recebimento de Solicitação**
    -   Coletores visualizam as solicitações disponíveis.
4.  **Confirmação de Coleta**
    -   Coletores podem enviar uma proposta.
    -   Usuários podem **aceitar** ou **rejeitar** a proposta.
5.  **Histórico de Coletas**
    -   Usuários e coletores podem ver histórico de solicitações anteriores.

---

## :handshake: Colaboradores

- [![Foto de Lucas Batista](https://github.com/LucasBatista37.png?size=100)](https://github.com/LucasBatista37)  
  **Lucas Batista**  
  Função: Desenvolvedor Front-End & Mobile  
  GitHub: [@LucasBatista37](https://github.com/LucasBatista37)


-   [![Foto de Rafael Almeida](https://github.com/rafokez.png?size=100)](https://github.com/rafokez)   
  **Rafael Almeida**  
  Função: Desenvolvedor Backend & Designer  
  GitHub: [@rafokez](https://github.com/rafokez)


---

## :wave: Contato

Em caso de dúvidas ou sugestões:

-   **E-mail**: [lucas.batista9734@gmail.com](mailto:lucas.batista9734@gmail.com)
-   **LinkedIn**: [www.linkedin.com/in/lucas-batista-004212263/](https://linkedin.com/in/lucas-batista-004212263)
-   **GitHub**: [https://github.com/LucasBatista37](https://github.com/LucasBatista37)