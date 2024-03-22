class BranchesController < AuthenticatedController
  def index
    @branches = Branch.all
  end
	def new
		@branch = Branch.new
	end
	def create
	  @branch = Branch.create(branch_params)
	  @branch.business = Business.first
	  if @branch.save
	    redirect_to branches_url, notice: "Branch created successfully"
	  else
	    render :new
	  end
	end
  def show
    @branch = Branch.find(params[:id])
  end

	private
	def branch_params
		params.require(:branch).permit(:name)
	end
end
