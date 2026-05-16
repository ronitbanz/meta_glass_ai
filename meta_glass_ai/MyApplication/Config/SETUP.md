## Local secrets setup (do not commit)

This repo keeps secret values out of `Info.plist` by using build-setting substitution:

- `$(URL_SCHEME)`
- `$(MWDAT_CLIENT_TOKEN)`
- `$(MWDAT_META_APP_ID)`
- `$(MWDAT_APP_LINK_URL_SCHEME)`

### 1) Create your local secrets file

`Config/Secrets.xcconfig` is ignored by git via `.gitignore`.
Create a file called Secrets.xcconfig, place in this location Config/Secrets.xcconfig add your keys in this file

URL_SCHEME =
MWDAT_CLIENT_TOKEN = 
MWDAT_META_APP_ID = 
MWDAT_APP_LINK_URL_SCHEME = 
 
### 2) Tell Xcode to use it

In Xcode:

1. Select the project in the navigator
2. Select the **MyApplication** target
3. Go to **Build Settings**
4. Under **User-Defined** (or search for the variable names), add:
   - `URL_SCHEME`
   - `MWDAT_CLIENT_TOKEN`
   - `MWDAT_META_APP_ID`
   - `MWDAT_APP_LINK_URL_SCHEME`
5. Set each value to `$(inherited)` plus your secret values, or set them directly.

Alternative (recommended):

1. Add `Config/Secrets.xcconfig` to the project (File → Add Files…)
2. Select the target → **Build Settings** → set **Base Configuration** (Debug/Release) to `Config/Secrets.xcconfig`
