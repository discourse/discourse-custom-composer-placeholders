import { apiInitializer } from "discourse/lib/api";
import I18n from "discourse-i18n";

export default apiInitializer((api) => {
  api.registerValueTransformer(
    "composer-editor-reply-placeholder",
    ({ value, context }) => {
      const composerModel = context.model.model;
      const categoryId = composerModel.categoryId;
      const isReply = composerModel.topic;

      // skip if no category
      if (!categoryId) {
        return value;
      }

      // track mode changes to ensure placeholder refresh
      if (!composerModel._lastComposerMode) {
        composerModel._lastComposerMode = isReply ? "reply" : "new_topic";
      }

      const modeChanged =
        (composerModel._lastComposerMode === "reply" && !isReply) ||
        (composerModel._lastComposerMode === "new_topic" && isReply);

      composerModel._lastComposerMode = isReply ? "reply" : "new_topic";

      let config = settings.placeholder_configurations.find((setting) => {
        if (setting.category_id) {
          return setting.category_id.includes(categoryId);
        }
      });

      // if inheritance is enabled and no direct configuration found, check parent categories
      if (!config && settings.inherit_parent_placeholders) {
        const category = composerModel.category;

        // if we have a category and it has a parent, try to find placeholder config for parent
        if (category && category.parent_category_id) {
          const parentCategoryId = category.parent_category_id;

          config = settings.placeholder_configurations.find((setting) => {
            if (setting.category_id) {
              return setting.category_id.includes(parentCategoryId);
            }
          });
        }
      }

      let placeholderText = "";

      if (config) {
        if (isReply && config.reply_placeholder) {
          placeholderText = config.reply_placeholder;
        } else if (!isReply && config.topic_placeholder) {
          placeholderText = config.topic_placeholder;
        }
      }

      if (!placeholderText) {
        return value;
      }

      // placeholders expect a translation key, so we create a temporary one below
      const contextPart = isReply ? "reply" : "topic";
      const translationKey = `custom_placeholder_${categoryId}_${contextPart}`;

      if (!composerModel._placeholderTranslationKey) {
        composerModel._placeholderTranslationKey = "";
      }

      if (
        translationKey !== composerModel._placeholderTranslationKey ||
        modeChanged
      ) {
        const locale = I18n.locale;
        I18n.translations[locale] = I18n.translations[locale] || {};
        I18n.translations[locale].js = I18n.translations[locale].js || {};
        I18n.translations[locale].js[translationKey] = placeholderText;

        composerModel._placeholderTranslationKey = translationKey;
      }

      return `js.${translationKey}`;
    }
  );
});
