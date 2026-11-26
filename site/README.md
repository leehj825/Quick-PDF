# QuickPDF website (static)

Plain HTML, no build step, no external scripts or fonts. Upload the contents of this folder to any static host
(GitHub Pages, Netlify, Cloudflare Pages, S3, ...).

| File | What it is |
|---|---|
| `index.html` | Landing + support page (English / 한국어, switch in the header) |
| `privacy.html` | Privacy policy, linked from the landing page header and footer |
| `app-ads.txt` | AdMob app-ads.txt. **Must be served at the domain root:** `https://YOUR-DOMAIN/app-ads.txt` |
| `assets/` | Icon, favicon, screenshots |
| `.nojekyll` | Only needed for GitHub Pages |

## Before publishing: replace the placeholder
Every contact address is the placeholder `YOUR_EMAIL@example.com`. Replace it everywhere:

```bash
sed -i 's/YOUR_EMAIL@example.com/you@your-domain.com/g' site/index.html site/privacy.html
grep -rn "YOUR_EMAIL" site/ || echo "all placeholders replaced"
```

## URLs to give to Google
- **Play Console -> Store presence -> Privacy policy:** `https://YOUR-DOMAIN/privacy.html`
- **Play Console -> Store listing -> Website:** `https://YOUR-DOMAIN/`  (AdMob checks `app-ads.txt` on this site's root domain)
- **AdMob -> Apps -> app-ads.txt:** verification can take up to a day or more after the Play listing is live.

The "Get it on Google Play" button already points to
`https://play.google.com/store/apps/details?id=app.quickpdf.quick_pdf` (works once the app is published).

## Keep the policy true
`privacy.html` describes what the app does today: no accounts or servers, on-device processing, Google AdMob ads, Google ML Kit
Document Scanner and Play in-app review. If you add analytics, crash reporting, sign-in or a consent form, update it
(and the Play "Data safety" form). This is a plain-language policy, not legal advice.

The in-app link to the policy is not added yet (Play recommends one); once you have the final URL it is a one-line change.
