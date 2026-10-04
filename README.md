# 35DDP257 - Profesyonel iOS & CarPlay DJ Konsolu

Modern Swift ve SwiftUI mimarisiyle geliştirilmiş, iPhone üzerinde profesyonel bir gece kulübü DJ konsolu deneyimi yaşatan ve araç CarPlay bağlantısı kurulduğunda Apple'ın sürüş güvenliği standartlarına (%100 App Store ve CPTemplate uyumlu) uygun araç içi DJ arayüzü sunan hibrit DJ uygulaması.

---

## 🎧 1. Temel Özellikler & Tasarım

* **Profesyonel Gece Kulübü UI:** Koyu antrasit (#0B0D14) zemin üzerinde Deck A için **Neon Cyan (#00F2FF)** ve Deck B için **Neon Magenta (#FF0D8D)** dinamik ışıklandırma.
* **Etkileşimli Jog Wheel & Scratch:** Parmak hareketinin açısal hızını (`ScratchProcessor`) hesaplayarak `AVAudioUnitVarispeed` üzerinden gerçek zamanlı sıfır gecikmeli ses manipülasyonu.
* **Dinamik Ses Dalgası (Waveform):** Ses dosyasının PCM tamponunu okuyarak oluşturulan interaktif ve parmakla sarılabilir (seek/scrub) dalga formu.
* **Çift Deck (Deck A & Deck B):** Bağımsız ses kontrolü, BPM göstergesi, Cue noktası belirleme, beat loop ve pitch fader (+/-%16).
* **Akıllı Crossfader:** Eşit güç (equal-power `cos/sin` eğrisi) ile Deck A ve Deck B arasında kesintisiz miksaj ve tek dokunuşla otomatik geçiş ("Auto Mix").
* **Gelişmiş Güvenlik Kapısı (Access Gate):** İlk açılışta 6 haneli DJ ana şifre oluşturma, Keychain'de tuzlanmış (salted) SHA-256 ile saklama, Face ID / Touch ID biyometrik doğrulama ve arka plana alındığında otomatik kilitleme.
* **Apple CarPlay Sürüş Modu:** Sürüş esnasında sürücünün dikkatini dağıtmayacak, Apple CarPlay Audio App şablonlarına (`CPTabBarTemplate`, `CPListTemplate`, `CPNowPlayingTemplate`) tam uyumlu büyük butonlu araç konsolu.
* **Hibrit Müzik ve Spotify Desteği:** Yerel MP3/WAV/M4A parçalarıyla tam DJ motoru; Spotify Web API (OAuth 2.0 PKCE) ile playlist, albüm ve BPM keşfi.

---

## 📊 2. Teknik Fizibilite & Platform Kuralları Analizi

| Soru | Durum | Teknik Gerçeklik & Mimari Çözüm |
| :--- | :---: | :--- |
| **1. Spotify sesinde gerçek zamanlı scratch yapılabilir mi?** | ❌ **HAYIR** | Spotify SDK ve API'leri DRM korumalıdır. Ham PCM ses tamponuna erişim kesinlikle verilmez (Spotify Dev Policy IV.3). Bu sebeple Spotify parçalarında pitch-bend/scratch yapılamaz. |
| **2. Spotify'da iki parçaya crossfade yapılabilir mi?** | ⚠️ **Kısıtlı** | Spotify aynı anda tek bir aktif ses çıkışına izin verir. İki Spotify şarkısı Deck A ve Deck B'ye aynı anda yüklenemez. Yerel parçalarla çift deck miksi yapılır. |
| **3. Spotify ses akışına doğrudan erişilebilir mi?** | ❌ **HAYIR** | Spotify ham ses akışı vermez, yalnızca uzaktan kumanda (Remote Play/Pause) komutlarına izin verir. |
| **4. Spotify playlistleri çekilebilir mi?** | ✅ **EVET** | Spotify Web API (REST) ile kullanıcının tüm çalma listeleri ve şarkı listesi uygulamaya aktarılır. |
| **5. Spotify albümleri gösterilebilir mi?** | ✅ **EVET** | Spotify Web API ile albümler ve yüksek çözünürlüklü kapaklar listelenir. |
| **6. Kendi MP3/WAV/M4A dosyalarımızda scratch yapılabilir mi?** | ✅ **EVET** | `AVAudioEngine`, `AVAudioPCMBuffer` ve `AVAudioUnitVarispeed` ile %100 sıfır gecikmeli scratch mümkündür. |
| **7. CarPlay üzerinde özel döner jog wheel çizilebilir mi?** | ❌ **HAYIR** | Apple, sürüş güvenliği nedeniyle CarPlay üzerinde serbest SwiftUI çizimine ve karmaşık sürükleme jestlerine izin vermez. |
| **8. Apple CarPlay şablon kısıtlamaları nelerdir?** | ℹ️ **Standart** | Sadece `CPTemplate` (`CPTabBarTemplate`, `CPListTemplate`, `CPNowPlayingTemplate`) kullanılabilir. Büyük butonlar ve güvenli menüler şarttır. |
| **9. iOS arka planda kesintisiz ses çalabilir mi?** | ✅ **EVET** | `UIBackgroundModes` -> `audio`, `AVAudioSession` (`.playback`) ve `MPRemoteCommandCenter` ile kilit ekranında ve CarPlay'de kesintisiz çalar. |
| **10. İki deck aynı anda çalıştırılabilir mi?** | ✅ **EVET** | Yerel kütüphanede iki adet `AVAudioPlayerNode` eş zamanlı çalışır ve crossfader ile mikslenir. |

---

## 🚗 3. CarPlay Araç Deneyimi Nasıl Çalışır?

iPhone aracın USB portuna veya kablosuz CarPlay sistemine bağlandığında `CarPlaySceneDelegate` otomatik devreye girer:
1. **DJ Konsol Sekmesi:**
   * **DJ Auto Mix ➔ Deck B (veya Deck A):** Sürüş sırasında direksiyondan veya ekrandan tek dokunuşla deckler arası yumuşak crossfade geçişi yapar.
   * **Oynat / Duraklat:** Aktif deck'in müziğini durdurur veya başlatır.
   * **CUE Deck A / CUE Deck B:** Şarkının başına anında dönüş sağlar.
   * **Çalan Parça Ekranı:** Apple'ın resmi NowPlaying ekranına geçiş yapar.
2. **Playlistler & Albümler Sekmesi:** Araç ekranında büyük yazı tipiyle oluşturulmuş çalma listeleri arasında gezinip şarkıyı doğrudan aktif olmayan karşı deck'e yükleme imkanı.
3. **Direksiyon Kontrolleri:** Direksiyondaki ses açma/kapama, şarkı atlama (Next/Prev) tuşları `MPRemoteCommandCenter` ile doğrudan DJ motoruna bağlıdır.

---

## 🔐 4. Güvenlik ve Kimlik Doğrulama

* **PIN Güvenliği:** İlk açılışta kullanıcıdan 6 basamaklı DJ şifresi oluşturması istenir (`isInitialSetup`).
* **Kriptografik Tuzlama (Salting):** Şifre düz metin olarak saklanmaz. 16 baytlık rastgele kriptografik tuz (salt) oluşturulur ve `CryptoKit` SHA-256 ile özetlenerek iOS `Keychain`'e kaydedilir.
* **Biyometri:** Face ID veya Touch ID ile tek dokunuşla kilit açılabilir.
* **Kilitlenme Önlemi (Rate Limiting):** 5 hatalı denemede sistem 30 saniye süreyle kilitlenir.
* **Arka Plan Koruması:** Uygulama arka plana gönderildiğinde veya ekran kilitlendiğinde güvenlik amacıyla kendini otomatik olarak kilitler.

---

## 📂 5. Proje Dosya Yapısı

```
35DDP257/
├── App/
│   ├── DJApp.swift                      # SwiftUI App giriş noktası & Scene yönetimi
│   ├── SceneDelegate.swift              # iOS pencere sahne yöneticisi
│   └── Info.plist                       # Audio background modes & CarPlay manifest
├── Authentication/
│   ├── KeychainService.swift            # Güvenli tuzlu SHA-256 PIN saklayıcı
│   ├── BiometricAuthService.swift       # Face ID / Touch ID (LocalAuthentication)
│   ├── AuthViewModel.swift              # Şifre doğrulama ve kilit mantığı
│   └── AccessGateView.swift             # Gece kulübü temalı neon tuş takımı UI
├── DJEngine/
│   ├── AudioEngineManager.swift         # AVAudioEngine, 2x PlayerNode, Varispeed, Mixer
│   ├── DJDeck.swift                     # Deck A ve Deck B durum yöneticisi
│   ├── ScratchProcessor.swift           # Jog wheel açısal hız ve scratch algoritması
│   └── WaveformExtractor.swift          # PCM ses dalgası analiz motoru
├── Library/
│   ├── MusicFileManager.swift           # MP3/WAV/M4A dosya içe aktarma yöneticisi
│   ├── ID3MetadataReader.swift          # AVURLAsset ile etiket ve kapak okuma
│   ├── LocalMusicStore.swift            # Şarkı, albüm ve playlist veritabanı
│   └── Models/
│       ├── Track.swift                  # Parça modeli
│       ├── Playlist.swift               # Çalma listesi modeli
│       └── Album.swift                  # Albüm modeli
├── Spotify/
│   ├── SpotifyAuthManager.swift         # OAuth 2.0 PKCE giriş yöneticisi
│   ├── SpotifyAPIService.swift          # REST API istekleri (Playlist, BPM, vb.)
│   ├── SpotifyRemoteController.swift    # Oynatma kontrolleri ve durum takibi
│   └── SpotifyModels.swift              # Spotify veri modelleri
├── CarPlay/
│   ├── CarPlaySceneDelegate.swift       # CPTemplateApplicationSceneDelegate
│   ├── CarPlayTemplateManager.swift     # Sürüş güvenliği onaylı CPTemplate menüleri
│   └── CarPlayDJController.swift        # Araç ekranı DJ köprüsü
├── Views/
│   ├── MainDJConsoleView.swift          # Ana DJ konsol görünümü
│   ├── Components/
│   │   ├── DeckView.swift               # Tam donanımlı Deck bileşeni
│   │   ├── JogWheelView.swift           # Dönen neon jog wheel & scratch
│   │   ├── WaveformView.swift           # Parmakla sarılabilir neon dalga formu
│   │   ├── CrossfaderView.swift         # A<->B geçiş fader'ı
│   │   ├── VUMeterView.swift            # LED ses seviye göstergesi
│   │   └── LibraryModalView.swift       # Deck'e hızlı şarkı yükleme modalı
│   ├── Library/
│   │   ├── LibraryTabView.swift         # Şarkı/Playlist/Albüm yönetimi
│   │   └── TrackDetailEditView.swift    # ID3 etiket düzenleme ekranı
│   └── Spotify/
│       └── SpotifyBrowserView.swift     # Spotify keşif ve kontrol ekranı
└── Utilities/
    ├── Theme.swift                      # Gece kulübü neon stilleri ve renkleri
    └── AudioSessionConfigurator.swift   # Arka plan oynatma ve kesinti yöneticisi
```

---

## 🚀 6. Kurulum ve Çalıştırma Kılavuzu

### Gereksinimler:
* macOS Sonoma veya üzeri (kod geliştirme ve derleme için)
* Xcode 15 veya 16+
* iOS 16.0+ çalıştıran iPhone veya iOS Simulator

### Adım Adım Çalıştırma:
1. `35DDP257` klasörünü Mac bilgisayarınıza kopyalayın veya Xcode ile açın:
   * Xcode menüsünden **File ➔ Open** seçin ve `35DDP257` klasörünü açın.
2. **Signing & Capabilities:**
   * Xcode projesinde Target seçin.
   * `Signing & Capabilities` sekmesinde `Background Modes` altındaki **Audio, AirPlay, and Picture in Picture** kutucuğunun işaretli olduğundan emin olun (bu ayar `Info.plist` içinde önceden tanımlanmıştır).
3. **İlk Çalıştırma & Şifre Belirleme:**
   * Uygulamayı çalıştırın. Ekranda **"ENTER DJ ACCESS CODE"** ekranı gelecektir.
   * İlk açılışta 6 haneli istediğiniz bir şifreyi girip onaylayarak DJ kilit kodunuzu oluşturun.
4. **Müzik Yükleme:**
   * Alt kısımdaki **Kütüphane** sekmesine gidin veya sağ üstteki `+` ikonuna dokunun.
   * Cihazınızdaki veya iCloud Drive'ınızdaki herhangi bir **MP3, WAV veya M4A** dosyasını seçin.
   * Şarkı otomatik olarak analiz edilecek, ID3 kapak resmi ve dalga formu çıkarılacaktır.
   * Şarkının yanındaki **DECK A** veya **DECK B** butonuna basarak konsola yükleyin.
5. **DJ Performansı:**
   * **Play:** Deck üzerindeki Play butonuna basarak müziği başlatın.
   * **Scratch:** Jog wheel üzerine parmağınızı koyup ileri-geri çevirerek gerçek zamanlı scratch yapın.
   * **Waveform:** Dalga formunun istediğiniz yerine dokunarak anında seek yapın.
   * **Crossfader:** Ortadaki fader'ı kaydırarak veya **AUTO MIX** butonuna basarak Deck A ile Deck B arasında yumuşak geçiş yapın.
6. **CarPlay Simülatöründe Test:**
   * Xcode Simulator çalışırken üst menüden **I/O ➔ External Displays ➔ CarPlay** seçeneğini aktif edin.
   * Yan tarafta araç ekranı açılacak ve `35DDP257 DJ` simgesi görünecektir. Araç ekranından güvenli DJ kontrollerini deneyimleyebilirsiniz.
