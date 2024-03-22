module ComputerRepairSection
  class WorkOrderUpdatesController < AuthenticatedController
    def create
      @work_order_update = Post.create(update_params)
      @work_order_update.user = current_user
      if @work_order_update.valid?

        if @work_order_update.updateable.technician.blank?
          @work_order_update.updateable.technician_id = current_user.id
        end

        @work_order_update.save
        @work_order_update.updateable.add_technician(current_user)
        redirect_to computer_repair_section_work_order_url(@work_order_update.updateable), notice: "Update saved successfully."
      else
        redirect_to computer_repair_section_work_order_url(@work_order_update.updateable), alert: "Update not accepted. Please complete update details."
      end
    end

    def edit
      @post = Post.find(params[:id])
    end
    def update
      @post = Post.find(params[:id])
      @post.update(update_params)
      if @post.valid?
        @post.save
        redirect_to computer_repair_section_work_order_url(@work_order_update.updateable), notice: "Update info updated successfully."
      else
        render :edit
      end
    end

    def destroy
      @post = Post.find(params[:id])
      @post.destroy
      redirect_to computer_repair_section_work_order_url(@post.updateable), notice: "Update info updated successfully."
    end

    private
    def update_params
      params.require(:post).permit(:type, :title, :content, :date, :updateable_id, :updateable_type)
    end
  end
end
