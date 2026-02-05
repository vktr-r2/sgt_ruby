class Admin::AdminController < ApplicationController
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
    return render json: { error: "Invalid table" }, status: :bad_request unless valid_table?(table_name)

    model = table_name.classify.constantize
    records = model.all

    if model.respond_to?(:includes) && associations_for_table(table_name).any?
      records = records.includes(associations_for_table(table_name))
    end

    # Apply filters for match_picks
    if table_name == "match_picks"
      records = records.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      records = records.where(user_id: params[:user_id]) if params[:user_id].present?
      records = records.where(golfer_id: params[:golfer_id]) if params[:golfer_id].present?
    end

    # Apply sorting
    if params[:sort_by].present? && model.column_names.include?(params[:sort_by])
      direction = params[:sort_direction] == "desc" ? :desc : :asc
      records = records.order(params[:sort_by] => direction)
    end

    render json: {
      data: format_records_for_display(records, table_name),
      columns: get_table_columns(model),
      table_name: table_name,
      lookups: get_lookups_for_table(table_name),
      total_count: records.size
    }
  end

  def create_record
    table_name = params[:table]
    return render json: { error: "Invalid table" }, status: :bad_request unless valid_table?(table_name)

    model = table_name.classify.constantize
    record = model.new(record_params(model))

    if record.save
      render json: { record: record, message: "Record created successfully" }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  end

  def update_record
    table_name = params[:table]
    return render json: { error: "Invalid table" }, status: :bad_request unless valid_table?(table_name)

    model = table_name.classify.constantize
    record = model.find(params[:id])

    if record.update(record_params(model))
      # Ensure updated_at is refreshed and reload the record to get the latest timestamps
      record.reload
      render json: { record: record, message: "Record updated successfully" }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Record not found" }, status: :not_found
  end

  def delete_record
    table_name = params[:table]
    return render json: { error: "Invalid table" }, status: :bad_request unless valid_table?(table_name)

    model = table_name.classify.constantize
    record = model.find(params[:id])

    if record.destroy
      render json: { message: "Record deleted successfully" }
    else
      render json: { errors: record.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Record not found" }, status: :not_found
  end

  private

  def valid_table?(table_name)
    %w[users golfers tournaments match_picks match_results scores].include?(table_name)
  end

  def associations_for_table(table_name)
    case table_name
    when "match_picks"
      [ :user, :tournament, :golfer ]
    when "match_results"
      [ :user, :tournament ]
    when "scores"
      [ match_pick: [ :golfer, :user ] ]
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

  def get_lookups_for_table(table_name)
    lookups = {}

    case table_name
    when "match_picks"
      lookups[:users] = User.all.map { |u| { id: u.id, name: u.name } }
      lookups[:golfers] = Golfer.all.map { |g| { id: g.id, name: "#{g.f_name} #{g.l_name}" } }
      lookups[:tournaments] = Tournament.all.map { |t| { id: t.id, name: t.name } }
    when "match_results"
      lookups[:users] = User.all.map { |u| { id: u.id, name: u.name } }
      lookups[:tournaments] = Tournament.all.map { |t| { id: t.id, name: t.name } }
    when "scores"
      lookups[:match_picks] = MatchPick.includes(:user, :golfer).map do |mp|
        { id: mp.id, name: "#{mp.user&.name} - #{mp.golfer&.f_name} #{mp.golfer&.l_name}" }
      end
    end

    lookups
  end

  def format_records_for_display(records, _table_name)
    records.map(&:attributes)
  end

  def record_params(model)
    permitted_attributes = model.column_names - %w[id created_at updated_at]
    params.require(:record).permit(permitted_attributes)
  end
end
