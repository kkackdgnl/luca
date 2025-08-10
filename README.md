# JARVIS KR — Android (Capacitor) Starter

이 폴더는 **APK를 직접 빌드**하기 위한 최소 프로젝트입니다.
웹앱 소스는 `web/` 폴더에 들어있고, Capacitor로 Android WebView 앱으로 감쌉니다.

## 필요한 것
- Node.js 18+ / npm
- Android Studio (SDK, 플랫폼 도구 설치)
- Java 17 (Android Gradle 플러그인 호환)

## 설치 & 빌드
```bash
npm install
# Android 프로젝트 생성(최초 1회)
npx cap add android

# 웹 변경사항 복사
npm run cap:copy

# Android Studio 열기
npm run cap:open
```

Android Studio에서:
- 상단 툴바의 **Run ▶** 으로 기기/에뮬레이터 실행 → APK 설치/실행
- 또는 **Build > Build Bundle(s)/APK(s) > Build APK(s)** 로 APK 산출

## 앱 설정 변경
- 패키지명: `capacitor.config.ts`의 `appId` 수정 (예: `com.yourcompany.jarvis`)
- 앱 이름: `appName` 수정
- 아이콘: `android/app/src/main/res/mipmap-*/ic_launcher.*` (Android Studio에서 Image Asset로 교체 권장)

## 음성 인식
- WebView 엔진에 따라 Web Speech API가 제한될 수 있습니다.
- 더 높은 인식률/안정성을 원하면 **네이티브 SpeechRecognizer** 브릿지(플러그인) 적용을 권장합니다.
  (원하면 템플릿 제공 가능)

## 개발 서버로 미리보기
```bash
npm run serve
# 브라우저에서 http://127.0.0.1:8080
```

---
문의/개조 포인트: 패키지명, 아이콘, 권한, STT 네이티브화, 스플래시/테마, 백그라운드 알람 등.
