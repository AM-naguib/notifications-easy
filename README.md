# EasyOrders Notification Stack

This workspace now contains two parts:

- `backend/`: a `FastAPI + SQLite` queue API with a small `/admin` dashboard.
- `ios/`: a `SwiftUI` iPhone app scaffold that fetches pending orders and schedules local notifications.

## Backend Quick Start

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Optional environment variables:

- `EASYORDERS_DB_PATH`: custom SQLite path
- `EASYORDERS_APP_TOKEN`: enables simple token protection for API and `/admin`

Example:

```powershell
$env:EASYORDERS_APP_TOKEN = "secret-token"
uvicorn app.main:app --reload
```

## iPhone App Quick Start

The iOS app is scaffolded with `XcodeGen` because this machine cannot generate an `.xcodeproj` directly.

1. On macOS, install `XcodeGen`.
2. Open the `ios/` folder in Terminal.
3. Run:

```bash
xcodegen generate
open EasyOrders.xcodeproj
```

4. Set your team + bundle identifier in Xcode.
5. Build/sign, then export the app for your SideStore workflow.

## Build Without Owning a Mac

If you do not have a Mac, this repo now includes a GitHub Actions workflow that runs on a hosted macOS runner and produces an `unsigned IPA` artifact.

### GitHub Actions path

1. Create a GitHub repository and push this project.
2. Open the `Actions` tab.
3. Run the workflow named `Build iOS Unsigned IPA`.
4. Download the artifact named `EasyOrders-unsigned-ipa`.
5. Try installing that IPA with SideStore.

Notes:

- The workflow uses GitHub's hosted `macOS` runners.
- The output is an unsigned IPA intended for SideStore-style re-signing flows.
- If a future SideStore or iOS change rejects unsigned builds, the fallback is to use a temporary cloud Mac session and export a signed IPA there.

## API Summary

- `GET /v1/health`
- `POST /v1/orders`
- `GET /v1/orders/pending?limit=5`
- `POST /v1/orders/ack`
- `GET /admin`

If token protection is enabled, send `X-App-Token: <token>` to the JSON API and append `?token=<token>` when opening `/admin`.
