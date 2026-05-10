#!/usr/bin/env node
// Hebrew text fixer — reads text from stdin, writes fixed text to stdout.
// Usage: node fix.js [mode]
//   mode: auto (default) | engToHeb | hebToEng | visualToLogical | logicalToVisual
//         | dosToWin | winToDos | htmlEncode | htmlDecode | urlEncode | urlDecode
//         | fixEncoding | reverseWords | cleanUrl

const fs = require('fs');

const ENG_TO_HEB = {
  'q':'/','w':"'",'e':'ק','r':'ר','t':'א','y':'ט','u':'ו','i':'ן','o':'ם','p':'פ',
  'a':'ש','s':'ד','d':'ג','f':'כ','g':'ע','h':'י','j':'ח','k':'ל','l':'ך',';':'ף',
  'z':'ז','x':'ס','c':'ב','v':'ה','b':'נ','n':'מ','m':'צ',',':'ת','.':'ץ','/':'.',
  'Q':'/','W':"'",'E':'ק','R':'ר','T':'א','Y':'ט','U':'ו','I':'ן','O':'ם','P':'פ',
  'A':'ש','S':'ד','D':'ג','F':'כ','G':'ע','H':'י','J':'ח','K':'ל','L':'ך',
  'Z':'ז','X':'ס','C':'ב','V':'ה','B':'נ','N':'מ','M':'צ'
};
const HEB_TO_ENG = {};
for (const [k, v] of Object.entries(ENG_TO_HEB)) {
  if (!HEB_TO_ENG[v]) HEB_TO_ENG[v] = k;
}

const HEB_LETTERS = 'אבגדהוזחטיךכלםמןנסעףפץצקרשת';

const LATIN_HEBREW_MAP = {
  'à':'א','á':'ב','â':'ג','ã':'ד','ä':'ה','å':'ו','æ':'ז','ç':'ח',
  'è':'ט','é':'י','ê':'ך','ë':'כ','ì':'ל','í':'ם','î':'מ','ï':'ן',
  'ð':'נ','ñ':'ס','ò':'ע','ó':'פ','ô':'ף','õ':'צ','ö':'ץ','÷':'ק',
  'ø':'ר','ù':'ש','ú':'ת'
};

const HTML_NAMED = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' };

const TRACKING_PARAMS = new Set([
  'utm_source','utm_medium','utm_campaign','utm_term','utm_content','utm_id',
  'rcm','ref','referral','fbclid','gclid','gclsrc','dclid','msclkid',
  '_ga','_gl','mc_eid','mc_cid','igshid','s_kwcid','ef_id',
  'share','feature','src','source','origin','trk','trkInfo',
  'fb_action_ids','fb_action_types','fb_ref','fb_source'
]);

const COMMON_MAPPED_HEBREW_WORDS = new Set([
  'אני','אתה','את','הוא','היא','אנחנו','אתם','אתן','הם','הן',
  'שלום','תודה','כן','לא','מה','מי','איך','למה','כמה','איפה',
  'זה','זו','של','עם','על','אל','או','גם','יש','אין','כל',
  'טוב','בסדר','עכשיו','צריך','רוצה','אפשר','עברית','טקסט',
  'קישור','מחשב','תוכנה','קובץ','דפדפן','חלון'
]);

function hasBadHebrewFinalLetters(text) {
  return text.split(/\s+/).some(word => /[ךםןףץ][א-ת]/.test(word));
}

function looksLikeUsefulHebrewMapping(text) {
  const mapped = engToHeb(text);
  if (hasBadHebrewFinalLetters(mapped)) return false;

  const words = mapped.match(/[א-ת]+/g) || [];
  if (words.some(w => COMMON_MAPPED_HEBREW_WORDS.has(w))) return true;

  const hebChars = (mapped.match(/[א-ת]/g) || []).length;
  const finalAtWordEnd = (mapped.match(/[א-ת]*[ךםןףץ](?=\s|$|[.,!?;:])/g) || []).length;
  const commonLetters = (mapped.match(/[איהוילמתש]/g) || []).length;

  if (hebChars <= 3) return commonLetters >= 2;
  return finalAtWordEnd > 0 || commonLetters / hebChars > 0.55;
}

function dosToWindows(t) {
  let r = '';
  for (let i = 0; i < t.length; i++) {
    const c = t.charCodeAt(i);
    if (c >= 0x05D0 && c <= 0x05EA) { r += t[i]; continue; }
    r += (c >= 128 && c <= 154) ? HEB_LETTERS[c - 128] : t[i];
  }
  return r;
}

function windowsToDos(t) {
  let r = '';
  for (let i = 0; i < t.length; i++) {
    const idx = HEB_LETTERS.indexOf(t[i]);
    r += idx >= 0 ? String.fromCharCode(128 + idx) : t[i];
  }
  return r;
}

function reverseText(t) {
  return t.split('\n').map(l => l.split('').reverse().join('')).join('\n');
}

function reverseWords(t) {
  return t.split('\n').map(l => l.split(' ').reverse().join(' ')).join('\n');
}

function rtlToLtr(t) { return t.replace(/[‏‎‪-‮]/g, '') + '‎'; }
function ltrToRtl(t) { return t.replace(/[‏‎‪-‮]/g, '') + '‏'; }

function htmlEncode(t) {
  return t.split('').map(ch => {
    const c = ch.charCodeAt(0);
    if (c > 127) return '&#' + c + ';';
    return { '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' }[ch] || ch;
  }).join('');
}

function htmlDecode(t) {
  return t
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(parseInt(d, 10)))
    .replace(/&([a-zA-Z]+);/g, (m, name) => HTML_NAMED[name] !== undefined ? HTML_NAMED[name] : m);
}

function urlEncode(t) { return encodeURIComponent(t); }

function urlDecode(t) {
  try { return decodeURIComponent(t); }
  catch { try { return unescape(t); } catch { return t; } }
}

function fixEncoding(t) {
  const lhc = (t.match(/[àáâãäåæçèéêëìíîïðñòóôõö÷øùú]/g) || []).length;
  const tot = t.replace(/\s/g, '').length;

  if (tot > 0 && lhc > tot * 0.2) {
    return t.replace(/[àáâãäåæçèéêëìíîïðñòóôõö÷øùú]/g, ch => LATIN_HEBREW_MAP[ch] || ch);
  }

  if (/×[\x80-\xBF]/.test(t) || t.includes('Ã') || /×[^ ]/.test(t)) {
    try {
      const b = [];
      for (let i = 0; i < t.length; i++) b.push(t.charCodeAt(i) & 0xFF);
      const d = Buffer.from(b).toString('utf8');
      if (/[א-ת]/.test(d)) return d;
    } catch {}

    try {
      const b = [];
      for (let i = 0; i < t.length; i++) b.push(t.charCodeAt(i) & 0xFF);
      const s1 = Buffer.from(b).toString('utf8');
      const b2 = [];
      for (let i = 0; i < s1.length; i++) b2.push(s1.charCodeAt(i) & 0xFF);
      const s2 = Buffer.from(b2).toString('utf8');
      if (/[א-ת]/.test(s2)) return s2;
    } catch {}
  }

  return t;
}

function engToHeb(t) {
  return t.split('').map(ch => ENG_TO_HEB[ch] || ch).join('');
}

function hebToEng(t) {
  return t.split('').map(ch => HEB_TO_ENG[ch] || ch).join('');
}

function cleanUrl(raw) {
  raw = raw.trim();
  let url;
  try { url = new URL(raw); } catch { return raw; }
  const keep = [];
  for (const [k, v] of url.searchParams) {
    if (!TRACKING_PARAMS.has(k.toLowerCase())) keep.push([k, v]);
  }
  const out = new URL(url.origin + url.pathname);
  keep.forEach(([k, v]) => out.searchParams.append(k, v));
  out.hash = url.hash;
  return out.toString();
}

function autoDetect(t) {
  if (!t.trim()) return null;
  const heb = (t.match(/[א-ת]/g) || []).length;
  const eng = (t.match(/[a-zA-Z]/g) || []).length;
  const tot = t.replace(/\s/g, '').length;

  if (/^https?:\/\//i.test(t.trim()) && t.includes('?')) {
    return { type: 'cleanUrl', desc: 'URL with query params' };
  }

  if (/&#\d+;|&amp;|&lt;|&gt;|&quot;|&#x[0-9a-f]+;/i.test(t)) {
    return { type: 'htmlDecode', desc: 'HTML entities' };
  }

  if (/%[0-9A-Fa-f]{2}/.test(t)) {
    return { type: 'urlDecode', desc: 'URL encoding' };
  }

  const lhc = (t.match(/[àáâãäåæçèéêëìíîïðñòóôõö÷øùú]/g) || []).length;
  if (tot > 0 && lhc > tot * 0.2) {
    return { type: 'fixEncoding', desc: 'Latin-1 mojibake' };
  }

  if (/×[\x80-\xBF]/.test(t) || /×[א-ת]/.test(t) || t.includes('×©') || t.includes('×¢')) {
    return { type: 'fixEncoding', desc: 'UTF-8 double encoding' };
  }

  if (heb > 3) {
    const firstWord = t.trim().split(/\s/)[0];
    if (/^[םןךףץ]/.test(firstWord)) {
      return { type: 'visualToLogical', desc: 'Visual Hebrew (final letters at start)' };
    }
  }

  if (eng > heb && eng > tot * 0.5 && tot > 2) {
    const mapped = t.replace(/[^a-zA-Z;,./']/g, '').split('').filter(c => ENG_TO_HEB[c]);
    const englishOnlyCount = t.replace(/[^a-zA-Z]/g, '').length;
    if (mapped.length > englishOnlyCount * 0.7 && looksLikeUsefulHebrewMapping(t)) {
      return { type: 'engToHeb', desc: 'English typed on Hebrew keyboard' };
    }
  }

  if (heb > eng && heb > tot * 0.5 && tot > 2) {
    const mapped = t.split('').filter(c => HEB_TO_ENG[c]);
    if (mapped.length > heb * 0.7) {
      const looksLikeWord = /^[a-zA-Z]/.test(hebToEng(t).trim());
      if (looksLikeWord) return { type: 'hebToEng', desc: 'Hebrew typed on English keyboard' };
    }
  }

  const dosChars = (t.match(/[\x80-\x9E]/g) || []).length;
  if (dosChars > 0) return { type: 'dosToWin', desc: 'DOS Hebrew (CP862)' };

  return null;
}

function applyFix(input, mode) {
  if (mode === 'auto' || !mode) {
    const det = autoDetect(input);
    if (!det) return input;
    return applyFix(input, det.type);
  }
  switch (mode) {
    case 'rtl2ltr': return rtlToLtr(input);
    case 'ltr2rtl': return ltrToRtl(input);
    case 'reverseWords': return reverseWords(input);
    case 'visualToLogical':
    case 'logicalToVisual': return reverseText(input);
    case 'engToHeb': return engToHeb(input);
    case 'hebToEng': return hebToEng(input);
    case 'dosToWin': return dosToWindows(input);
    case 'winToDos': return windowsToDos(input);
    case 'htmlEncode': return htmlEncode(input);
    case 'htmlDecode': return htmlDecode(input);
    case 'urlEncode': return urlEncode(input);
    case 'urlDecode': return urlDecode(input);
    case 'fixEncoding': return fixEncoding(input);
    case 'cleanUrl': return cleanUrl(input);
    default: return input;
  }
}

function main() {
  const mode = (process.argv[2] || 'auto').trim();
  const inputFile = process.argv[3];
  const outputFile = process.argv[4];
  let input = inputFile ? fs.readFileSync(inputFile, 'utf8') : fs.readFileSync(0, 'utf8');
  if (input.charCodeAt(0) === 0xFEFF) input = input.slice(1);
  const out = applyFix(input, mode);
  if (outputFile) fs.writeFileSync(outputFile, out, 'utf8');
  else process.stdout.write(out);
}

if (require.main === module) main();

module.exports = { applyFix, autoDetect };
