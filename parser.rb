require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'pry'

PAGE_URL = 'http://aromalux.by'
NAMES = ['- ЖЕНСКАЯ -', '- МУЖСКАЯ -']

page = Nokogiri::HTML(open PAGE_URL)
@categories_li = page.css('li.main')
@id = 1000

@categories_li.each do |c|
	@category_name = c.text
	next if NAMES.include? @category_name 

	category_page = Nokogiri::HTML(open(PAGE_URL + c.children[0].attributes['href'].value))
	products_divs = category_page.css('div.product')

	Dir.mkdir(c.text) unless Dir.exist? @category_name

	products_divs.each do |p|
		product_name = p.css('h3 a')[0].text.delete('/')
		product_dir = "#{@category_name}/#{product_name}/"
		product_link = p.css('a.image')[0]['href']
		product_page = Nokogiri::HTML(open(PAGE_URL + product_link))
		@image_link = URI.escape(p.css('img')[0]['src'])
		@thumb_link = @image_link.sub('medium', 'thumb')

		Dir.mkdir(product_dir) unless Dir.exist? product_dir
		
		description_name = product_dir + 'description.txt'
		@description = product_page.css('div.description p').text
		unless File.exist?(description_name)
			File.open(description_name, 'w') { |file| file.write(@description) }
		end

		old_price_name = product_dir + 'old_price.txt'
		@old_price = product_page.css('div.data.sale')[0].text.split("\n")[1].strip.gsub(/\D/, '')
		unless File.exist?(old_price_name)			
			File.open(old_price_name, 'w') { |file| file.write(@old_price) }
		end
		
		new_price_name = product_dir + 'new_price.txt'
		@new_price = product_page.css('div.data.sale')[0].text.split("\n")[2].strip.gsub(/\D/, '')
		unless File.exist?(new_price_name)
			File.open(new_price_name, 'w') { |file| file.write(@new_price) }
		end	
		
		image_name = product_dir + @image_link.split('/')[-1]
		unless File.exist?(image_name)
			image = open @image_link
			IO.copy_stream(image, image_name) 
		end

		thumb_name = product_dir + @thumb_link.split('/')[-1]
		unless File.exist?(thumb_name)
			thumb = open @thumb_link
			IO.copy_stream(thumb, thumb_name) 
		end
		
		CSV.open("products.csv", "a+", {col_sep: ";"}) do |csv|
  		csv << [@id+=1, product_name, @description, "да", "BYR", @new_price, "Без НДС", "нет", "шт", @category_name, "", "", "100", @thumb_link, @image_link]
		end
	end
end


