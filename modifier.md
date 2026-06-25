# Charlink Connect — Modifier Document

**Purpose:** Complete record of all changes made to the PHPNuxBill upstream codebase to produce Charlink Connect. Written for independent review and verification by another model or developer.

**Repository:** https://github.com/MarkCalebChomba/charlink-system  
**Branch to review:** `mpesa-integration`  
**Base branch:** `main` (clean upstream PHPNuxBill)  
**Total files changed:** 115 (5 new, 109 modified, 1 deleted)  
**Commits:** 9 (listed chronologically below)

---

## How to Verify

Clone and compare:
```bash
git clone https://github.com/MarkCalebChomba/charlink-system
cd charlink-system
git fetch origin
git diff main mpesa-integration --stat
git diff main mpesa-integration -- <filename>
```

---

## Commit 1 — feat: Add M-Pesa STK Push payment gateway

**Files created:**
- `system/paymentgateway/mpesa.php`
- `system/paymentgateway/ui/mpesa.tpl`

**What these do:**

`mpesa.php` implements the PHPNuxBill payment gateway plugin interface. PHPNuxBill loads gateways by requiring the file and calling functions named `{gateway}_{action}`. The following 6 functions must exist and are verified present:

| Function | Line | Purpose |
|---|---|---|
| `mpesa_validate_config()` | 197 | Returns true if all 5 config keys are set |
| `mpesa_show_config()` | 207 | Renders the admin config form (mpesa.tpl) |
| `mpesa_save_config()` | 214 | Saves credentials to tbl_appconfig |
| `mpesa_create_transaction($trx, $user)` | 257 | Initiates STK Push via Daraja API |
| `mpesa_get_status($trx, $user)` | 342 | Queries STK Push status |
| `mpesa_payment_notification()` | 432 | Handles Safaricom callback webhook |

**Verify function signatures:**
```bash
grep -n "^function mpesa_" system/paymentgateway/mpesa.php
```
Expected output: 6 lines, one per function above.

**Config keys stored in tbl_appconfig:**
- `mpesa_consumer_key`
- `mpesa_consumer_secret`
- `mpesa_shortcode`
- `mpesa_passkey`
- `mpesa_environment` (values: `sandbox` or `production`)

**Daraja API endpoints used:**

| Operation | Sandbox | Production |
|---|---|---|
| OAuth Token | `https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials` | `https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials` |
| STK Push | `https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest` | `https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest` |
| Query | `https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query` | `https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query` |

**Callback URL generated:** `{base_url}/index.php?_route=callback/mpesa`  
This routes to `mpesa_payment_notification()` via `system/controllers/callback.php` line 14:
```php
if (function_exists($action . '_payment_notification')) {
    call_user_func($action . '_payment_notification');
}
```
`$action` is derived from the URL segment `callback/mpesa` → `$action = 'mpesa'`.

**Verify callback routing:**
```bash
grep -n "payment_notification\|call_user_func" system/controllers/callback.php
```

**Phone number normalization in `mpesa_create_transaction`:**  
Reads phone from `_post('phone')` first, falls back to `$user['phonenumber']`.  
Normalizes all Kenyan formats:
- `07XXXXXXXX` (10 digits) → `254XXXXXXXXX`  
- `01XXXXXXXX` (10 digits) → `254XXXXXXXXX`  
- `254XXXXXXXXX` (12 digits, starts with 254) → unchanged

**Verify phone handling:**
```bash
grep -n "_post.*phone\|phone.*254\|strlen.*phone" system/paymentgateway/mpesa.php
```

**Account reference in STK Push:** Uses `$config['CompanyName']` (no hardcoded strings).

**Verify no hardcoded Reduzer/PHPNuxBill strings:**
```bash
grep -n "Reduzer\|PHPNuxBill\|phpnuxbill\|hotspotbilling" system/paymentgateway/mpesa.php
```
Expected: no output.

`mpesa.tpl` renders the admin configuration form. Contains input fields for all 5 config keys and a dropdown for sandbox/production environment.

---

## Commit 2 — feat: Set Kenya locale defaults in install SQL

**File modified:** `install/phpnuxbill.sql` (line 422)

**Before:**
```sql
VALUES (1, 'CompanyName', 'PHPNuxBill'), (2, 'currency_code', 'Rp.'), ... (6, 'timezone', 'Asia/Jakarta'), (7, 'dec_point', ','), (8, 'thousands_sep', '.'), ...
```

**After:**
```sql
VALUES (1, 'CompanyName', 'Charlink Connect'), (2, 'currency_code', 'KES'), ... (6, 'timezone', 'Africa/Nairobi'), (7, 'dec_point', '.'), (8, 'thousands_sep', ','), ...
```

**Changes:**
| Key | Before | After |
|---|---|---|
| CompanyName | PHPNuxBill | Charlink Connect |
| currency_code | Rp. | KES |
| timezone | Asia/Jakarta | Africa/Nairobi |
| dec_point | , (comma) | . (period) |
| thousands_sep | . (period) | , (comma) |

**Note:** This only affects fresh installs. Existing installs read these values from the `tbl_appconfig` table which is not modified by this change.

**Verify:**
```bash
grep "CompanyName\|currency_code\|timezone\|dec_point\|thousands_sep" install/phpnuxbill.sql | head -3
```

---

## Commit 3 — feat: Add M-Pesa and onboarding language strings to english.json

**File modified:** `system/lan/english.json`

**Rule followed:** Translation keys were NOT changed. Only new key-value pairs were appended. This preserves compatibility with all other language files (indonesia.json, arabic.json, spanish.json, turkish.json) which will fall back to English for any key they don't define.

**18 new keys added:**
```json
"Mpesa_Payment": "Mpesa Payment",
"Quick_MPesa_Payment": "Quick MPesa Payment",
"Amount_to_Pay": "Amount to Pay",
"Your_MPesa_Number": "Your MPesa Number",
"Pay_Now_with_MPesa": "Pay Now with MPesa",
"Failed_to_connect_to_payment_server": "Failed to connect to payment server",
"Already_have_an_account_": "Already have an account?",
"Register_New_Account": "Register New Account",
"Register_as_New_Member": "Register as New Member",
"Create_My_Account": "Create My Account",
"Login_to_Your_Account": "Login to Your Account",
"Choose_Your_Internet_Package": "Choose Your Internet Package",
"Buy_Now": "Buy Now",
"Duration": "Duration",
"Validity_Period": "Validity Period",
"Package_Activated_": "Package Activated!",
"Connect_to_Internet": "Connect to Internet",
"web_browser_did_not_send_challenge_response__try_again__enable_JavaScript_": "web browser did not send challenge response (try again, enable JavaScript)"
```

**Verify keys exist and values are in English:**
```bash
python3 -c "import json; d=json.load(open('system/lan/english.json')); print(d.get('Mpesa_Payment')); print(d.get('Your_MPesa_Number')); print(len(d), 'total keys')"
```

**Verify no existing keys were modified unintentionally:**
```bash
git diff main mpesa-integration -- system/lan/english.json | grep "^-" | grep -v "^---" | grep -v "Installed_Devices"
```
Expected: only one removed line (the old last entry that had no trailing comma before the new keys were appended).

---

## Commit 4 — feat: Auto-login after registration and trigger Mikrotik auth on login

### register.php

**File modified:** `system/controllers/register.php`

**Location of change:** Inside `case 'post':` → `if ($d->save())` block (around line 120).

**Before (upstream line 124):**
```php
r2(getUrl('login'), 's', Lang::T('Register Success! You can login now'));
```

**After:**
```php
$_SESSION['uid'] = $user;
User::setCookie($user);
$d->last_login = date('Y-m-d H:i:s');
$d->save();
r2(U . 'order/package', 's', Lang::T('Register Success! You can login now'));
```

**What this does:** After a customer registers, they are immediately logged in (session set, cookie set, last_login updated) and redirected to the package selection page. They no longer have to log in manually after registering.

**Verify:**
```bash
grep -n "setCookie\|last_login\|order/package" system/controllers/register.php
```
Expected: lines 124-128 containing those 4 lines.

### login.php

**File modified:** `system/controllers/login.php`

**Location of change:** Inside the customer login success block (around line 53).

**Before (upstream line 53):**
```php
_alert(Lang::T('Login Successful'), 'success', "home");
```

**After:**
```php
_alert(Lang::T('Login Successful'), 'success', "home&mikrotik=login");
```

**What this does:** After login, the redirect target includes `mikrotik=login` which causes `home.php` to trigger the Mikrotik hotspot authentication flow immediately, connecting the customer to internet without a manual extra step.

**Verify:**
```bash
grep -n "mikrotik=login\|Login Successful" system/controllers/login.php
```
Expected: line ~53 shows `home&mikrotik=login`, line ~196 (admin login) remains `dashboard` unchanged.

**Important:** The admin login redirect (line 196) was NOT changed. Only the customer portal login is affected.

---

## Commit 5 — feat: Replace meta-refresh hotspot auth with async JS connection manager

**File modified:** `ui/ui/customer/dashboard.tpl`

**Condition:** This code only runs when all three are true:
- `$hostname` is set (Mikrotik router is configured)
- `$hchap == 'true'` (CHAP authentication enabled)
- `$_c['hs_auth_method'] == 'hchap'` (admin set auth method to hchap)

**Before (upstream):** A `document.write()` injected a `<meta http-equiv="refresh">` tag that opened the Mikrotik login URL after a 2-second delay with no confirmation of success or failure.

**After:** A self-contained IIFE (Immediately Invoked Function Expression) that:
1. Checks if internet is already connected before attempting auth
2. Creates a hidden iframe and loads the Mikrotik auth URL into it
3. After 3 seconds, checks connectivity by fetching `https://www.google.com/generate_204` (returns HTTP 204 with no body — standard connectivity probe)
4. Retries up to 3 times with 2-second gaps between attempts
5. Shows a progress bar and status message to the user throughout
6. On success: shows "Connected successfully"
7. On failure after all retries: shows error message with a "Try Again" button that reloads the page
8. Cleans up the iframe after completion

**Why this is better:** The old meta-refresh fired and forgot — the customer had no feedback and the system had no way to know if auth succeeded. The new approach confirms actual internet connectivity after each attempt.

**Verify the key structural difference:**
```bash
git diff main mpesa-integration -- ui/ui/customer/dashboard.tpl | grep "meta http-equiv\|document.write\|generate_204\|isAuthComplete"
```
Expected: `meta http-equiv` and `document.write` on `-` (removed) lines, `generate_204` and `isAuthComplete` on `+` (added) lines.

---

## Commit 6 — feat: Add M-Pesa STK Push payment UI with auto-connect on success

**Files created:**
- `ui/ui/scripts/vue.global.js` (Vue 3 runtime, 18,039 lines)

**Note on selectGatewayMpesa.tpl:** An orphaned file `ui/ui/customer/selectGatewayMpesa.tpl` was created in this commit but was later deleted in Commit 8 (fix commit). Nothing in the codebase routed to it. It does not exist in the final state of the branch.

---

## Commit 7 — feat: Simplified onboarding UI templates

**Files modified:**
- `ui/ui/customer/login.tpl`
- `ui/ui/customer/register.tpl`

### login.tpl

**What changed:** Layout simplified. Side announcement panel removed. Inputs made larger (Bootstrap `input-lg`). Register button moved below the login form with clearer label. Forgot password link made more prominent.

**What was NOT removed:** All `Lang::T()` translation calls preserved. CSRF token field preserved. All form action URLs preserved. The announcement modal at the bottom preserved.

**Verify critical elements still present:**
```bash
grep -n "csrf_token\|login/post\|Lang::T\|forgot\|register" ui/ui/customer/login.tpl
```

### register.tpl

**What changed:** Multi-column 3-step layout replaced with single centered column. Fullname and email fields are now hidden and auto-populated via JavaScript from the phone number field (since phone is the primary identifier for Kenyan hotspot users).

**Key JS behaviour:**
```javascript
document.getElementById('username').addEventListener('input', function() {
    document.getElementById('fullname').value = this.value;
    document.getElementById('email').value = this.value + '@hotspot.local';
});
```

The email domain `@hotspot.local` is a placeholder — it is never emailed to since most hotspot users don't have email. The domain was `@reduzer.tech` in the original Reduzer code; this was changed to `@hotspot.local` to remove Reduzer-specific branding.

**Verify:**
```bash
grep -n "hotspot.local\|fullname\|email\|username" ui/ui/customer/register.tpl
```

**What was NOT changed:** `orderView.tpl` — this was reverted to upstream in Commit 8 because the Reduzer version stripped out bandwidth info, data/time limits, invoice notes, router description, and the "Check for Payment" button.

---

## Commit 8 — fix: Correct M-Pesa gateway integration issues

This commit corrects problems introduced in earlier commits.

### mpesa.php fixes

**Fix 1: Phone parameter**

`order.php` calls `call_user_func($gateway . '_create_transaction', $d, $user)` — only 2 arguments. The original Reduzer implementation had `mpesa_create_transaction($trx, $user, $phone)` with 3 parameters, so `$phone` would always be `null`.

Fixed by removing `$phone` from the function signature and reading it internally:
```php
$phone = _post('phone');
if (empty($phone)) {
    $phone = $user['phonenumber'];
}
```

**Verify:**
```bash
grep -n "function mpesa_create_transaction\|_post.*phone\|user.*phonenumber" system/paymentgateway/mpesa.php
```
Expected: function signature has only `$trx, $user`, and `_post('phone')` appears inside the function body.

**Fix 2: Callback URL**

`callback.php` routes `callback/{action}` to `{action}_payment_notification()`. The original Reduzer code set callback URL to `callback/m-process-transaction/{trx_id}` which would look for a function named `m-process-transaction_payment_notification` — which does not exist.

Fixed to: `callback/mpesa` which correctly calls `mpesa_payment_notification()`.

**Verify:**
```bash
grep -n "callback_url" system/paymentgateway/mpesa.php
```
Expected: `$callback_url = U . 'callback/mpesa';`

**Fix 3: Hardcoded account reference**

STK Push `AccountReference` field was hardcoded as `"Reduzer"`. Fixed to `$config['CompanyName']`.

**Verify:**
```bash
grep -n "AccountReference\|CompanyName" system/paymentgateway/mpesa.php
```

### selectGateway.tpl — M-Pesa phone field added

`selectGateway.tpl` is displayed when a customer goes to pay for a package. The upstream version has no phone number input field. M-Pesa STK Push requires a phone number from the customer.

**What was added:** A phone number `<input>` field that is hidden by default and shown via JavaScript only when the customer selects "mpesa" as their gateway. A `validateAndAsk()` function replaces the standard `ask()` on the submit button — it validates phone format before allowing submit.

**Phone field location in file:** Around line 168.

**Verify:**
```bash
grep -n "mpesa-phone-field\|mpesa-phone\|validateAndAsk" ui/ui/customer/selectGateway.tpl
```
Expected: 3+ matches.

**Verify the field is hidden by default and shows only for M-Pesa:**
```bash
grep -A5 "mpesa-phone-field" ui/ui/customer/selectGateway.tpl | head -10
```
Expected: `display:none` in the div style, and JS that checks `gw.value === 'mpesa'` before showing.

### orderView.tpl — reverted to upstream

The Reduzer version of `orderView.tpl` was simpler but removed these features that exist in upstream:
- Bandwidth plan details (rate_down/rate_up)
- Data limit and time limit display for limited plans
- Invoice notes
- Router name and description for non-radius plans
- "Check for Payment" button for unpaid transactions
- Transaction ID in panel footer

Reverted to upstream version entirely.

**Verify it matches upstream:**
```bash
git diff main mpesa-integration -- ui/ui/customer/orderView.tpl
```
Expected: no diff output (files identical).

### selectGatewayMpesa.tpl — deleted

Orphaned file removed. Nothing in `order.php` or any controller routed to this template.

**Verify it does not exist:**
```bash
ls ui/ui/customer/selectGatewayMpesa.tpl 2>&1
```
Expected: `No such file or directory`

---

## Commit 9 — feat: Full rebrand from PHPNuxBill to Charlink Connect

### PHP file headers (69 files)

Every `.php` file in the codebase had a header comment block:
```php
/**
 *  PHP Mikrotik Billing (https://github.com/hotspotbilling/phpnuxbill/)
 *  by https://t.me/ibnux
 **/
```

Replaced with:
```php
/**
 *  Charlink Connect - Hotspot Billing (https://github.com/MarkCalebChomba/charlink-system)
 *  by Charlink Connect
 **/
```

**Verify across all PHP files:**
```bash
grep -rl "by https://t.me/ibnux" --include="*.php" . | wc -l
```
Expected: `0`

```bash
grep -rl "Charlink Connect - Hotspot Billing" --include="*.php" . | wc -l
```
Expected: `69` (or close — some files had variant header formats).

### config.sample.php

**Change:** Default database name.

```php
// Before:
$db_name = "phpnuxbill";

// After:
$db_name = "charlink_connect";
```

**Verify:**
```bash
grep "db_name" config.sample.php
```

### CSS files

Two new CSS files created as copies of the originals with Charlink branding names:
- `ui/ui/styles/charlink.css` (copy of phpnuxbill.css)
- `ui/ui/styles/charlink.customer.css` (copy of phpnuxbill.customer.css)

The original `.css` files are retained for backwards compatibility with any existing installations that may reference them. The header templates now reference the new names.

**Header references updated:**
- `ui/ui/admin/header.tpl` line 23: `phpnuxbill.css?2025.2.4` → `charlink.css?1.0.0`
- `ui/ui/customer/header.tpl` line 20: `phpnuxbill.customer.css?2025.2.4` → `charlink.customer.css?1.0.0`

**Verify:**
```bash
grep "charlink.css\|charlink.customer.css" ui/ui/admin/header.tpl ui/ui/customer/header.tpl
```

### Logo mini text

`ui/ui/customer/header.tpl` line 36:
```html
<!-- Before: -->
<span class="logo-mini"><b>N</b>uX</span>

<!-- After: -->
<span class="logo-mini"><b>CC</b></span>
```

**Verify:**
```bash
grep "logo-mini" ui/ui/customer/header.tpl
```

### Footer templates

`ui/ui/admin/footer.tpl` and `ui/ui/customer/footer.tpl`:
```html
<!-- Before: -->
PHPNuxBill by <a href="https://github.com/hotspotbilling/phpnuxbill" ...>

<!-- After: -->
Charlink Connect <a href="https://github.com/MarkCalebChomba/charlink-system" ...>
```

**Verify:**
```bash
grep -n "Charlink Connect\|PHPNuxBill" ui/ui/admin/footer.tpl ui/ui/customer/footer.tpl
```
Expected: only `Charlink Connect` lines, no `PHPNuxBill`.

### update.php

| Item | Before | After |
|---|---|---|
| Update ZIP URL | `https://github.com/hotspotbilling/phpnuxbill/archive/...master.zip` | `https://github.com/MarkCalebChomba/charlink-system/archive/refs/heads/main.zip` |
| Cache file | `system/cache/phpnuxbill.zip` | `system/cache/charlink.zip` |
| Cache folder | `system/cache/phpnuxbill-{version}/` | `system/cache/charlink-{version}/` |
| Success message | `PHPNuxBill has been updated` | `Charlink Connect has been updated` |

**Verify:**
```bash
grep -n "charlink\|update_url" update.php | head -6
```

### community.php

GitHub API calls for commit history now point to the Charlink Connect repo:
```
https://api.github.com/repos/MarkCalebChomba/charlink-system/commits?per_page=100
```

**Verify:**
```bash
grep -n "api.github.com" system/controllers/community.php
```

### settings.php

FreeRadius SQL download links updated to point to our repo:
```
https://raw.githubusercontent.com/MarkCalebChomba/charlink-system/main/install/radius.sql
```

**Verify:**
```bash
grep -n "raw.githubusercontent.com" system/controllers/settings.php
```

### Template files — bulk rebrand

All `.tpl` files under `ui/` had these replacements applied:
- `PHPNuxBill` → `Charlink Connect`
- `phpnuxbill` (in URLs) → `charlink-connect`
- `hotspotbilling/charlink-connect` → `MarkCalebChomba/charlink-system` (fixing the chain)
- `t.me/phpnuxbill` → `t.me/charlinkconnect`
- `t.me/ibnux` → GitHub repo link
- Donation links (trakteer, karyakarsa, paypal.me/ibnux) → GitHub repo link

**Exception — NOT changed:** Links to `github.com/hotspotbilling/android-printer` in `voucher/view.tpl` and `plan/invoice.tpl`. This is a separate Android Bluetooth printer app that is not part of this repo — the external link is correct.

**Verify no PHPNuxBill remains in templates:**
```bash
grep -rn "PHPNuxBill\|t\.me/phpnuxbill" --include="*.tpl" ui/
```
Expected: no output.

### Non-English text fixes

**Fix 1:** `ui/ui/admin/plan/active.tpl` line 10:
```
Before: "This will sync dan send Customer active package to Mikrotik"
After:  "This will sync and send Customer active package to Mikrotik"
```
("dan" is Indonesian for "and")

**Fix 2:** `README.md`:
```
Before: See [How it Works / Cara Kerja](https://github.com/hotspotbilling/phpnuxbill/wiki/How-It-Works---Cara-kerja)
After:  See [How it Works](https://github.com/MarkCalebChomba/charlink-system/wiki)
```
("Cara Kerja" is Indonesian for "How it Works")

**Verify:**
```bash
grep -n "dan\b\|Cara Kerja" ui/ui/admin/plan/active.tpl README.md
```
Expected: no output.

### README.md

Completely rewritten. The original README was in Indonesian/English mixed language and documented PHPNuxBill. The new README documents Charlink Connect with features, requirements, and links appropriate for a Kenya-focused hotspot billing system.

### composer.json

```json
// Before:
{
    "name": "hotspotbilling/phpnuxbill",
    "description": "PHPNuxBill a Hotspot Billing Software.",
    "keywords": ["template","PHPMixBill","PHPnuxBill","Mikrotik","Hotspot","Billing"],
    "homepage": "https://github.com/hotspotbilling/phpnuxbill"
}

// After:
{
    "name": "charlink/charlink-connect",
    "description": "Charlink Connect - Hotspot Billing System with M-Pesa integration.",
    "keywords": ["Mikrotik","Hotspot","Billing","MPesa","Kenya","Charlink"],
    "homepage": "https://github.com/MarkCalebChomba/charlink-system"
}
```

### Installer files (install/*.php)

All 6 installer PHP files had PHPNuxBill text replaced with Charlink Connect. These files are only used during initial installation and have no runtime impact.

**Verify:**
```bash
grep -rn "PHPNuxBill\|phpnuxbill\|ibnux" install/*.php
```
Expected: no output.

### pages_template HTML files

`pages_template/Privacy_Policy.html` and `pages_template/Terms_and_Conditions.html` had PHPNuxBill replaced with Charlink Connect throughout.

### english.json — translation values updated

In addition to the 18 new keys added in Commit 3, several existing translation values that contained "PHPNuxBill" were updated to "Charlink Connect". Translation KEYS were not changed.

**Verify keys are unchanged:**
```bash
python3 -c "
import json
with open('system/lan/english.json') as f:
    d = json.load(f)
# Check a few known keys that had PHPNuxBill in their values
print(d.get('Update_PHPNuxBill', 'KEY MISSING'))
print(d.get('Make_sure_your_Mikrotik_accessible_from_PHPNuxBill', 'KEY MISSING'))
"
```
Expected: Both keys exist (not "KEY MISSING"), and their values now say "Charlink Connect" instead of "PHPNuxBill".

---

## Critical Preservation Checks

These must be verified unchanged or the Mikrotik integration will break.

### nux-* session variables

PHPNuxBill uses these session keys to track Mikrotik captive portal context. If renamed, the hotspot login flow breaks entirely.

```bash
grep -rn "nux-mac\|nux-ip\|nux-router\|nux-key\|nux-hostname" --include="*.php" .
```
Expected: 32 occurrences across `index.php`, `system/controllers/home.php`, `system/controllers/autoload_user.php`. All must be unchanged from upstream.

**Verify they were not touched:**
```bash
git diff main mpesa-integration -- index.php | grep "nux-"
```
Expected: no output (no changes to nux-* in index.php).

### Database table names

All ORM calls use `tbl_*` prefixed table names. None were changed.

```bash
grep -rn "for_table\|tbl_" --include="*.php" system/ | grep -v "charlink\|Charlink" | wc -l
```
Expected: large number (hundreds). Run the same on master and compare — counts should match.

### Language file keys

Translation keys must not change or all `Lang::T('Key_Name')` calls throughout the codebase will return the raw key string instead of translated text.

```bash
# Count keys in english.json
python3 -c "import json; print(len(json.load(open('system/lan/english.json'))))"
```
Expected: 475 (457 original + 18 new).

```bash
# Verify key count didn't decrease (which would mean keys were deleted)
git diff main mpesa-integration -- system/lan/english.json | grep "^-" | grep -v "^---\|Installed_Devices" | wc -l
```
Expected: 1 (only the old last-entry line that lost its trailing comma when new entries were appended).

---

## What Was Intentionally NOT Changed

| Item | Reason |
|---|---|
| `system/lan/indonesia.json`, `arabic.json`, `spanish.json`, `turkish.json` | These are translation catalogs. Changing values would break those languages. They will fall back to English for any key they don't define. |
| Links to `github.com/hotspotbilling/android-printer` | External Bluetooth printer app. Not part of this repo. Correct to leave as-is. |
| `ui/ui/styles/phpnuxbill.css` and `phpnuxbill.customer.css` | Kept alongside new charlink.css files for backwards compatibility with existing installs that may reference the old filenames. |
| `system/controllers/pages.php` and `system/autoload/Message.php` | These fetch page templates from the upstream GitHub repo. Since the templates themselves are unchanged, the upstream URL remains correct for now. |
| All `tbl_*` database table names | Would require a migration script and break existing installations. |
| Functional logic in all controllers | Only cosmetic text and header comments were changed in most files. |

---

## Things to Test After Deployment

1. **Fresh install:** Company name shows "Charlink Connect", currency shows "KES"
2. **M-Pesa config:** Admin → Payment Gateway → M-Pesa appears, all 5 fields save correctly
3. **STK Push:** Customer orders package → selects M-Pesa → phone field appears → enters number → submits → STK Push arrives on phone
4. **M-Pesa callback:** After PIN entry, Safaricom hits `{domain}/index.php?_route=callback/mpesa` → `mpesa_payment_notification()` runs → transaction status updates to paid
5. **Auto-login after register:** New customer registers → goes straight to package selection without seeing a login page
6. **Mikrotik auth on login:** Customer logs in → immediately tries to connect to Mikrotik hotspot
7. **Dashboard auto-connect:** Customer on dashboard with active HCHAP hotspot → sees "Connecting..." progress bar → either connects or gets retry button
8. **Admin panel:** No "PHPNuxBill" text visible anywhere in the UI
9. **Customer portal:** No "PHPNuxBill" text visible anywhere in the UI
10. **Language switcher:** Switch to Indonesian, Spanish, Arabic, Turkish — UI should still render (falling back to English for new keys)
11. **Mikrotik session variables:** Complete a hotspot login cycle — confirm `$_SESSION['nux-mac']` etc. are set correctly
12. **Order flow:** Non-M-Pesa gateway (e.g. manual/balance) — M-Pesa phone field should NOT appear, normal flow should be unaffected

---

## Repository State Summary

| Branch | Content |
|---|---|
| `main` | Clean upstream PHPNuxBill (no changes) |
| `mpesa-integration` | All changes documented above |

To merge to production: open a pull request from `mpesa-integration` into `main` at https://github.com/MarkCalebChomba/charlink-system/compare/main...mpesa-integration

