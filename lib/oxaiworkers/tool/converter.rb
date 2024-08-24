# def getDocument doc1, &block
#   document = getFileBin(doc1)
#   content = nil
#   unless document.nil?
#     extension = doc1['file_name'].split('.').last.downcase
#     if extension == "docx"
#       docx = Docx::Document.open document#.read
#       content = docx.instance_variable_get("@doc").xpath('//w:document//w:body').children.map{ |c|
#         if c.name == 'p' # paragraph
#           paragraph = docx.send(:parse_paragraph_from, c)
#           ReverseMarkdown.convert(paragraph.to_html).strip
#         elsif c.name = 'tbl' # table
#           table = docx.send(:parse_table_from, c)
#           table.rows.map { |row| row.cells.map { |cell| cell.paragraphs.map(&:text).reject { |c| c.empty? }.join("\\n ") }.join(" | ") }.join("\n")
#         else # other types?
#           c.content
#         end
#       }.reject { |c| c.empty? }.join("\n\n")
#       #content = ReverseMarkdown.convert(docx.to_html)
#       makeTempFileWithContent(content, ["file_#{@current_user.id}", ".txt"]) do |file|
#         yield(content, doc1['file_name'], file)
#       end
#     elsif %w[xlsx xls ods].include?(extension)
#       xlsx = Roo::Spreadsheet.open document, extension: extension.to_sym
#       content = xlsx.to_csv
#       makeTempFileWithContent(content, ["file_#{@current_user.id}", ".csv"]) do |file|
#         yield(content, doc1['file_name'], file)
#       end
#     elsif %w[csv txt ini asc log kicad_sch cpp h rb c hpp erb md yml].include?(extension)
#       yield(document.read.force_encoding("UTF-8"), doc1['file_name'], nil)
#     else
#       yield(nil, doc1['file_name'], nil)
#     end
#   end
# end
