import { createI18n } from 'vue-i18n'
import en from "./locales/en.json";
//import de from "./locales/de.json";

export const messages = {
  'en': en,
  //'de': de,
}

export default createI18n({
  locale: 'en',
  fallbackLocale: 'en',
  messages
})
