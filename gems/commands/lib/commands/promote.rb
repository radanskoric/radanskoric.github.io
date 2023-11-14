module Commands
  class Promote < Jekyll::Command
    class << self
      def init_with_program(prog)
        prog.command(:promote) do |c|
          c.description 'Generate promotion links with correct UTM params for latest blog post'
          c.action do |args, options|
            site = Jekyll::Site.new(Jekyll.configuration)
            site.process
            post_doc = site.posts.docs.last

            puts "TITLE"
            puts post_doc.data['title']
            puts "----------------------------------------------------------------"

            print_channel(post_doc, "RUBYFLOW", "rubyflow", "feed") do |url|
              "<a href=\"#{url}\">#{post_doc.data["title"]}</a>"
            end
            print_channel(post_doc, "REDDIT", "reddit", "forum")
            print_channel(post_doc, "RUBY ON RAILS LINK SLACK", "ruby-on-rails-link", "slack")
            print_channel(post_doc, "RUBYZG SLACK", "rubyzg", "slack")
            print_channel(post_doc, "LINKEDIN", "linkedin", "social")
          end
        end
      end

      private

      def print_channel(doc, channel_name, source, medium)
        puts channel_name
        url = utm_link(doc, source, medium)
        if block_given?
          puts yield(url)
        else
          puts url
        end
        puts "---------------------------------------"
      end

      def utm_link(doc, source, medium)
        "https://radanskoric.com#{doc.url}?utm_source=#{source}&utm_medium=#{medium}&utm_campaign=#{doc.data["slug"]}"
      end
    end
  end
end
