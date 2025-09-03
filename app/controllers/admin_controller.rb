class AdminController < ApplicationController
  before_action :authenticate_admin!

  def index
    tables = {
      users: User.all,
      golfers: Golfer.all,
      tournaments: Tournament.all,
      match_picks: MatchPick.includes(:user, :tournament, :golfer),
      match_results: MatchResult.includes(:user, :tournament),
      scores: Score.includes(:match_pick)
    }
    
    render json: { tables: tables }
  end

  def table_data
    table_name = params[:table]
    return render json: { error: 'Invalid table' }, status: :bad_request unless valid_table?(table_name)
    
    model = table_name.classify.constantize
    records = model.all
    
    if model.respond_to?(:includes) && associations_for_table(table_name).any?
      records = records.includes(associations_for_table(table_name))
    end
    
    render json: {
      data: records,
      columns: get_table_columns(model),
      table_name: table_name
    }
  end

  def create_record
    table_name = params[:table]
    return render json: { error: 'Invalid table' }, status: :bad_request unless valid_table?(table_name)
    
    model = table_name.classify.constantize
    record = model.new(record_params(model))
    
    if record.save
      render json: { record: record, message: 'Record created successfully' }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  end

  def update_record
    table_name = params[:table]
    return render json: { error: 'Invalid table' }, status: :bad_request unless valid_table?(table_name)
    
    model = table_name.classify.constantize
    record = model.find(params[:id])
    
    if record.update(record_params(model))
      render json: { record: record, message: 'Record updated successfully' }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Record not found' }, status: :not_found
  end

  def delete_record
    table_name = params[:table]
    return render json: { error: 'Invalid table' }, status: :bad_request unless valid_table?(table_name)
    
    model = table_name.classify.constantize
    record = model.find(params[:id])
    
    if record.destroy
      render json: { message: 'Record deleted successfully' }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Record not found' }, status: :not_found
  end

  private

  def valid_table?(table_name)
    %w[users golfers tournaments match_picks match_results scores].include?(table_name)
  end

  def associations_for_table(table_name)
    case table_name
    when 'match_picks'
      [:user, :tournament, :golfer]
    when 'match_results'
      [:user, :tournament]
    when 'scores'
      [:match_pick]
    else
      []
    end
  end

  def get_table_columns(model)
    model.column_names.map do |column|
      {
        name: column,
        type: model.column_for_attribute(column).type,
        null: model.column_for_attribute(column).null
      }
    end
  end

  def record_params(model)
    permitted_attributes = model.column_names - %w[id created_at updated_at]
    params.require(:record).permit(permitted_attributes)
  end
end