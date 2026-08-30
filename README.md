# 🇨🇳 ➔ 🇬🇧 Pinduoduo Real-Time iOS AI Translator

Real-time Chinese-to-English screen translation app for iOS, specially tailored for **Pinduoduo (拼多多)**, Taobao, and Chinese e-commerce apps.

Features:
- 🚀 **Zero Local Mac Storage Required**: Compiled 100% in the cloud via GitHub Actions.
- 📺 **Floating Picture-in-Picture (PiP) Subtitle Overlay**: Floats on top of Pinduoduo while you scroll.
- ⚡ **Lightning Fast Vision OCR**: On-device Apple Vision framework for Chinese character detection (`zh-Hans` & `zh-Hant`).
- 🤖 **AI Gateway Integration**: Pre-configured for `https://ai.gmcdev.app/v1` using `gemini-3.7-flash-high`.
- 🔑 **Bring Your Own API Key (BYO)**: Change API keys, models, and custom prompts anytime in Settings.

---

## 🛠 Cloud Build & Sideloading (Step-by-Step)

### Step 1: Push to your GitHub Account
1. Open Terminal in this folder:
   ```bash
   cd /Users/glennmarkcruz/PinduoduoTranslatorApp
   git init
   git add .
   git commit -m "Initial commit for Pinduoduo Translator iOS"
   ```
2. Create a new repository on GitHub (e.g. `pinduoduo-ios-translator`).
3. Push your code:
   ```bash
   git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/pinduoduo-ios-translator.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Download the Compiled IPA
1. Go to your GitHub repository in your browser.
2. Click the **Actions** tab.
3. Click the latest run: **Build iOS IPA (No Mac Storage Needed)**.
4. Once completed (takes ~2-3 minutes), scroll down to **Artifacts** and download **`PinduoduoTranslator-iOS-IPA`**.
5. Unzip the downloaded file to get `PinduoduoTranslator.ipa`.

### Step 3: Install on your iPhone with Sideloadly (No Xcode SDK needed)
1. Download & open **[Sideloadly](https://sideloadly.io/)** on your Mac (~50MB app, zero heavy storage needed).
2. Connect your iPhone to your Mac via USB cable.
3. Drag and drop `PinduoduoTranslator.ipa` into Sideloadly.
4. Enter your **Apple ID email** (this is used by Apple to sign the app for personal use).
5. Click **Start**.
6. Once completed, the app will appear on your iPhone home screen!

### Step 4: Trust Developer Certificate on iPhone
1. On your iPhone, open **Settings** > **General** > **VPN & Device Management**.
2. Under *Developer App*, tap your **Apple ID**.
3. Tap **Trust [Your Apple ID]** and confirm.
4. (iOS 16+): Go to **Settings** > **Privacy & Security** > Scroll to bottom > Enable **Developer Mode** and restart device if prompted.

---

## 📱 How to Use with Pinduoduo

1. Open **PDD Translator** on your iPhone.
2. Verify settings (Default endpoint: `https://ai.gmcdev.app/v1`, Model: `gemini-3.7-flash-high`).
3. Tap **Start Floating PiP Translator**.
4. Swipe up to go to your Home screen. The floating PiP window will remain visible.
5. Open **Pinduoduo (拼多多)**.
6. The floating window will display English translations of item titles, specs, prices, discounts, and reviews as you browse!
