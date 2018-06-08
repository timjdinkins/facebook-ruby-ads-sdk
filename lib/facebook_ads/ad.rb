module FacebookAds
  # An ad belongs to an ad set. It is created using an ad creative.
  # https://developers.facebook.com/docs/marketing-api/reference/adgroup
  class Ad < Base
    FIELDS   = %w[id account_id campaign_id adset_id adlabels bid_amount bid_info bid_type configured_status conversion_specs created_time creative effective_status last_updated_by_app_id name tracking_specs updated_time ad_review_feedback].freeze
    STATUSES = %w[ACTIVE PAUSED DELETED PENDING_REVIEW DISAPPROVED PREAPPROVED PENDING_BILLING_INFO CAMPAIGN_PAUSED ARCHIVED ADSET_PAUSED].freeze

    # belongs_to ad_account

    def ad_account
      @ad_account ||= AdAccount.find(account_id)
    end

    # belongs_to ad_campaign

    def ad_campaign
      @ad_campaign ||= AdCampaign.find(campaign_id)
    end

    # belongs_to ad_set

    def ad_set
      @ad_set ||= AdSet.find(adset_id)
    end

    # belongs_to ad_creative

    def ad_creative
      @ad_creative ||= AdCreative.find(creative['id'])
    end

    def update_ad_creative( params )
      current = ad_creative
      object_story_spec = current.object_story_spec
      link_data = object_story_spec.link_data

      #new_creative_data = AdCreative.photo(
      new_creative_data = {
        name: current.name,
        page_id: object_story_spec.page_id,
        instagram_actor_id: object_story_spec.instagram_actor_id,
        message: link_data.message,
        link: params[ :link ] || link_data.link,
        link_title: link_data.name,
        image_hash: link_data.image_hash,
        call_to_action_type: link_data.call_to_action.type,
        link_description: link_data.description,
        url_tags: params[ :url_tags ] || current.url_tags,
        attachment_style: link_data.attachment_style,
        caption: link_data.caption
      }

      new_creative = ad_account.create_ad_creative( new_creative_data, creative_type: 'image' )

      query_data = { creative: { creative_id: new_creative.id }.to_json }
      update( query_data )
    end

    # has_many ad_insights

    def ad_insights(range: Date.today..Date.today, level: 'ad', time_increment: 1)
      query = {
        level: level,
        time_increment: time_increment,
        time_range: { 'since': range.first.to_s, 'until': range.last.to_s }
      }
      AdInsight.paginate("/#{id}/insights", query: query)
    end
  end
end
