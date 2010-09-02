module Portfolio::Extensions::DeleteAllMethod
  def delete_all
    with_scope current_scoped_methods do
      @reflection.klass.delete_all
    end
  end
end
