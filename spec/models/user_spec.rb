require 'rails_helper'

describe User do
  describe 'associations' do
    it { is_expected.to have_many :employee_cash_accounts }
    it { is_expected.to have_many :cash_accounts }
    it { is_expected.to have_many :work_orders }
    it { is_expected.to have_many(:user_store_fronts).dependent(:destroy) }
    it { is_expected.to have_many(:accessible_store_fronts).through(:user_store_fronts) }
  end

  describe '#switchable_store_fronts' do
    it 'includes the home store front even without granted access' do
      user = create(:sales_clerk)
      expect(user.switchable_store_fronts).to include(user.store_front)
    end

    it 'includes granted store fronts' do
      user = create(:sales_clerk)
      other = create(:store_front, business: user.business)
      user.user_store_fronts.create!(store_front: other)
      expect(user.switchable_store_fronts).to include(other)
    end
  end

  describe '#can_access_store_front?' do
    it 'allows the home store front and granted ones only' do
      user = create(:sales_clerk)
      granted = create(:store_front, business: user.business)
      denied = create(:store_front, business: user.business)
      user.user_store_fronts.create!(store_front: granted)
      expect(user.can_access_store_front?(user.store_front)).to be true
      expect(user.can_access_store_front?(granted)).to be true
      expect(user.can_access_store_front?(denied)).to be false
      expect(user.can_access_store_front?(nil)).to be false
    end
  end
end
