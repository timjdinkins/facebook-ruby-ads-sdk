module FacebookAds
  # An ad belongs to an ad set. It is created using an ad creative.
  # https://developers.facebook.com/docs/marketing-api/reference/adgroup
  class Ad < Base
    FIELDS   = %w[ id account_id campaign_id adset_id adlabels bid_amount bid_info bid_type configured_status conversion_specs created_time creative effective_status last_updated_by_app_id name tracking_specs updated_time ad_review_feedback ].freeze
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
      new_creative_data = {
        url_tags: params[ :url_tags ] || current.url_tags
      }

      if params[ :type ] == 'ptr'
        new_creative_data[ :object_story_id ] = current.object_story_id
        new_creative_data[ :instagram_actor_id ] = current.instagram_actor_id
      else
        if current.instagram_actor_id
          new_creative_data[ :instagram_actor_id ] = current.instagram_actor_id
        end
        object_story_spec = current.object_story_spec
        if object_story_spec
          link_data = if params[ :type ] == 'image'
                        object_story_spec.link_data
                      elsif params[ :type ] == 'link'
                        object_story_spec.link_data
                      elsif params[ :type ] == 'video'
                        object_story_spec.video_data
                      end

          new_creative_data[ :name ] = current.name
          new_creative_data[ :video_id ] = link_data.video_id
          new_creative_data[ :title ] = link_data.title
          new_creative_data[ :message ] = link_data.message
          new_creative_data[ :link ] = params[ :link ] || link_data.link
          new_creative_data[ :link_title ] = link_data.name
          new_creative_data[ :image_hash ] = link_data.image_hash
          new_creative_data[ :call_to_action_type ] = link_data.call_to_action.type
          new_creative_data[ :call_to_action_link_caption ] = link_data.call_to_action.value && link_data.call_to_action.value.link_caption
          new_creative_data[ :link_description ] = link_data.description || link_data.link_description
          new_creative_data[ :attachment_style ] = link_data.attachment_style
          new_creative_data[ :caption ] = link_data.caption
          new_creative_data[ :page_id ] = object_story_spec.page_id

          if object_story_spec.instagram_actor_id
            new_creative_data[ :instagram_actor_id ] = object_story_spec.instagram_actor_id
          end
        end
      end

      new_creative = ad_account.create_ad_creative( new_creative_data, creative_type: params[ :type ] )

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
