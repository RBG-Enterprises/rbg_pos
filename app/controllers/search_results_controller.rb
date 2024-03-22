class SearchResultsController < AuthenticatedController
  def index
    @pg_search_documents = PgSearch.multisearch(params[:multisearch])
  end
end
