describe ArbitrationRule do
  describe '#action' do
    it 'validates allowed actions' do
      expect { FactoryGirl.create(:arbitration_rule, :action => 'skip') }
        .to raise_error(ActiveRecord::RecordInvalid, /Action is not included in the list/)
    end
  end

  describe '#expression' do
    it 'requires an expression to be set' do
      expect { FactoryGirl.create(:arbitration_rule, :expression => nil) }
        .to raise_error(ActiveRecord::RecordInvalid, /Expression can't be blank/)
    end
  end

  describe '#name' do
    it 'requires a name' do
      expect { FactoryGirl.create(:arbitration_rule, :name => nil) }
        .to raise_error(ActiveRecord::RecordInvalid, /Name can't be blank/)
    end
  end
end
