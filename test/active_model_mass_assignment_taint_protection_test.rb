require 'test_helper'

class Person
  include ActiveModel::MassAssignmentSecurity
  include ActiveModel::ForbiddenAttributesProtection

  public :sanitize_for_mass_assignment
end

class ActiveModelMassUpdateProtectionTest < ActiveSupport::TestCase
  test "forbidden attributes cannot be used for mass updating" do
    assert_raises(ActionController::ParameterMissing) do
      Person.new.sanitize_for_mass_assignment(ActionController::Parameters.new(:a => "b").require(:c))
    end
  end
  
  test "forbidden attributes not passed on for mass updating when there are some matches" do
    assert_equal(
      {'c' => 'd'},
      Person.new.sanitize_for_mass_assignment(ActionController::Parameters.new(:a => "b", :c => 'd').permit(:c))
    )
  end
  
  test "attributes cannot be used for mass updating when nothing permitted" do
    assert_raises(ActiveModel::ForbiddenAttributes) do
      Person.new.sanitize_for_mass_assignment(ActionController::Parameters.new(:a => "b"))
    end
  end

  test "permitted attributes can be used for mass updating" do
    assert_nothing_raised do
      assert_equal({ "a" => "b" },
        Person.new.sanitize_for_mass_assignment(ActionController::Parameters.new(:a => "b").permit(:a)))
    end
  end

  test "regular attributes should still be allowed" do
    assert_nothing_raised do
      assert_equal({ :a => "b" },
        Person.new.sanitize_for_mass_assignment(:a => "b"))
    end
  end
end
