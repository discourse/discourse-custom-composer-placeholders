# frozen_string_literal: true
RSpec.describe "Custom Composer Placeholders", system: true do
  let!(:theme) { upload_theme_component }

  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:category) { Fabricate(:category) }
  fab!(:subcategory) { Fabricate(:category, parent_category_id: category.id) }
  fab!(:other_category) { Fabricate(:category) }

  before { sign_in(user) }

  describe "when placeholders are configured for a category" do
    before do
      theme.update_setting(
        :placeholder_configurations,
        [
          {
            category_id: [category.id],
            topic_placeholder: "Custom topic placeholder for category",
            reply_placeholder: "Custom reply placeholder for category"
          }
        ].to_json
      )
      theme.save!
    end

    it "shows custom topic placeholder when creating a new topic" do
      visit("/c/#{category.slug}")
      find("#create-topic").click

      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("Custom topic placeholder for category")
    end

    it "shows custom reply placeholder when replying to a topic" do
      topic = Fabricate(:topic, category: category)
      post = Fabricate(:post, topic: topic)
      
      visit("/t/#{topic.slug}/#{topic.id}")
      
      find(".reply").click
      
      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("Custom reply placeholder for category")
    end

    it "doesn't show custom placeholders in other categories" do
      visit("/c/#{other_category.slug}")
      find("#create-topic").click

      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).not_to include("Custom topic placeholder for category")
    end
  end

  describe "when parent category inheritance is enabled" do
    before do
      theme.update_setting(:inherit_parent_placeholders, true)
      
      theme.update_setting(
        :placeholder_configurations,
        [
          {
            category_id: [category.id],
            topic_placeholder: "Parent category topic placeholder",
            reply_placeholder: "Parent category reply placeholder"
          }
        ].to_json
      )
      theme.save!
    end

    it "inherits parent category placeholders in subcategories" do
      visit("/c/#{category.slug}/#{subcategory.slug}")
      find("#create-topic").click

      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("Parent category topic placeholder")
    end

    it "doesn't inherit when inheritance is disabled" do
      theme.update_setting(:inherit_parent_placeholders, false)
      theme.save!
      
      visit("/c/#{category.slug}/#{subcategory.slug}")
      find("#create-topic").click

      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).not_to include("Parent category topic placeholder")
    end

    it "uses subcategory placeholder when both parent and child have configurations" do
      theme.update_setting(
        :placeholder_configurations,
        [
          {
            category_id: [category.id],
            topic_placeholder: "Parent category topic placeholder",
            reply_placeholder: "Parent category reply placeholder"
          },
          {
            category_id: [subcategory.id],
            topic_placeholder: "Subcategory topic placeholder",
            reply_placeholder: "Subcategory reply placeholder"
          }
        ].to_json
      )
      theme.save!
      
      visit("/c/#{category.slug}/#{subcategory.slug}")
      find("#create-topic").click

      expect(page).to have_selector('.composer-fields')
      
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("Subcategory topic placeholder")
      expect(textarea['placeholder']).not_to include("Parent category topic placeholder")
    end
  end

  describe "switching between new topic and reply modes" do
    before do
      theme.update_setting(
        :placeholder_configurations,
        [
          {
            category_id: [category.id],
            topic_placeholder: "New topic specific placeholder",
            reply_placeholder: "Reply specific placeholder"
          }
        ].to_json
      )
      theme.save!
    end

    it "updates placeholder when switching from new topic to reply mode" do
      topic = Fabricate(:topic, category: category)
      post = Fabricate(:post, topic: topic)
      
      visit("/c/#{category.slug}")
      find("#create-topic").click
      
      expect(page).to have_selector('.composer-fields')
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("New topic specific placeholder")
      
      find(".toggle-minimize").click
      
      visit("/t/#{topic.slug}/#{topic.id}")
      find(".reply").click
      
      expect(page).to have_selector('.composer-fields')
      textarea = find('.d-editor-input')
      expect(textarea['placeholder']).to include("Reply specific placeholder")
    end
  end
end