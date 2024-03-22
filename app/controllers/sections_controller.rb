class SectionsController < AuthenticatedController
  def new
    @section = Section.new
  end
  def create
    @section = Section.create(section_params)
    if @section.save
      redirect_to settings_url, notice: "Section saved successfully"
    else
      render :new
    end
  end

  private
  def section_params
    params.require(:section).permit(:name)
  end
end
