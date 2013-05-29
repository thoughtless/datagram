Sequel.migration do
  change do
    add_column :queries, :locked, Boolean, :default => false
  end
end
