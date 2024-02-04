# frozen_string_literal: true

module DefaultWebActions
  extend ActiveSupport::Concern

  included do
    helper_method :record_type_humanized, :create_url, :update_url
  end

  def index
    @records = scope.all.page(params[:page])
  end

  def edit
    @record = scope.find(params[:id])
  end

  def new
    @record = scope.new
  end

  def update
    @record = scope.find(params[:id])

    if @record.update(update_params)
      after_successful_update
      redirect_to({ action: :index }, { notice: "#{record_type_humanized} updated" })
    else
      render :new
    end
  end

  def create
    @record = scope.new(create_params)

    if @record.save
      after_successful_create
      redirect_to({ action: :index }, { notice: "#{record_type_humanized} created" })
    else
      render :new
    end
  end

  def destroy
    @record = scope.find(params[:id])
    @record.destroy

    after_successful_destroy

    redirect_to({ action: :index }, { notice: "#{record_type_humanized} deleted" })
  end

  # def record_klass
  #   User
  # end

  def scope
    record_klass.all
  end

  def create_params
    create_or_update_params
  end

  def update_params
    create_or_update_params
  end

  # def create_or_update_params
  #   params.require(:foo).permit(:val1, :val2, :val3)
  # end

  def after_successful_update
    after_successful_create_update_or_destroy
  end

  def after_successful_create
    after_successful_create_update_or_destroy
  end

  def after_successful_destroy
    after_successful_create_update_or_destroy
  end

  def after_successful_create_update_or_destroy
    # by default, do nothing special
  end

  def record_type_humanized
    record_klass.to_s.humanize
  end

  def create_url
    { action: "create" }
  end

  def update_url(record)
    { action: "update", id: record.to_param }
  end
end
