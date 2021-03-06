require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before do
    @london = Address.new(:number => 1, :street => "Bond Street")
    @shanghai = Address.new(:number => 10, :street => "Nan Jing Dong Lu")
    @melbourne = Address.new(:number => 20, :street => "Bourke Street")
    @new_york = Address.new(:number => 20, :street => "Broadway")
    @docs = [ @london, @shanghai, @melbourne, @new_york ]
    @criteria = Mongoid::Criteria.new(Address)
    @criteria.documents = @docs
    @criteria.only(:number)
    @context = Mongoid::Contexts::Enumerable.new(@criteria)
  end

  describe "#aggregate" do

    before do
      @counts = @context.aggregate
    end

    it "groups by the fields provided in the options" do
      @counts.size.should == 3
    end

    it "stores the counts in proper groups" do
      @counts[1].should == 1
      @counts[10].should == 1
      @counts[20].should == 2
    end
  end

  describe "#avg" do

    it "returns the avg value for the supplied field" do
      @context.avg(:number).should == 12.75
    end
  end

  describe "#count" do

    it "returns the size of the enumerable" do
      @context.count.should == 4
    end

  end

  describe "#distinct" do

    context "when the criteria is limited" do

      before do
        @criteria.where(:street => "Bourke Street")
      end

      it "returns an array of distinct values for the field" do
        @context.distinct(:street).should == [ "Bourke Street" ]
      end
    end

    context "when the criteria is not limited" do

      before do
        @criteria = Mongoid::Criteria.new(Address)
        @criteria.documents = @docs
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns an array of distinct values for the field" do
        @context.distinct(:street).should ==
          [ "Bond Street", "Nan Jing Dong Lu", "Bourke Street", "Broadway" ]
      end
    end
  end

  describe "#execute" do

    before do
      @criteria = Mongoid::Criteria.new(Address)
      @criteria.documents = @docs
    end

    context "when the selector is present" do
      before do
        @criteria.where(:street => "Bourke Street")
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end
      it "returns the matching documents from the array" do
        @context.execute.should == [ @melbourne ]
      end
    end

    context "when selector is empty" do

      before do
        @criteria.only(:number)
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns all the documents" do
        @context.execute.should == @docs
      end
    end

    context "when skip and limit are in the options" do

      before do
        @criteria.skip(2).limit(2)
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "properly narrows down the matching results" do
        @context.execute.should == [ @melbourne, @new_york ]
      end
    end

    context "when limit is set without skip in the options" do

      before do
        @criteria.limit(2)
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "properly narrows down the matching results" do
        @context.execute.size.should == 2
      end

  end

  end

  describe "#first" do

    context "when a selector is present" do
      before do
        @criteria.where(:street => "Bourke Street")
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns the first that matches the selector" do
        @context.first.should == @melbourne
      end
    end

  end

  describe "#group" do

    before do
      @group = @context.group
    end

    it "groups by the fields provided in the options" do
      @group.size.should == 3
    end

    it "stores the documents in proper groups" do
      @group[1].should == [ @london ]
      @group[10].should == [ @shanghai ]
      @group[20].should == [ @melbourne, @new_york ]
    end

  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:documents) { [stub] }

    before do
      @criteria = Mongoid::Criteria.new(Address)
      @criteria.documents = documents
      @criteria.where(selector).skip(20)
      @context = Mongoid::Contexts::Enumerable.new(@criteria)
    end

    it "sets the selector" do
      @context.selector.should == selector
    end

    it "sets the options" do
      @context.options.should == options
    end

    it "sets the documents" do
      @context.documents.should == documents
    end

  end

  describe "#iterate" do
    before do
      @criteria.where(:street => "Bourke Street")
      @criteria.documents = @docs
      @context = Mongoid::Contexts::Enumerable.new(@criteria)
    end

    it "executes the criteria" do
      acc = []
      @context.iterate do |doc|
        acc << doc
      end
      acc.should == [@melbourne]
    end
  end

  describe "#last" do

    context "when the selector is present" do
      before do
        @criteria.where(:street => "Bourke Street")
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end
      it "returns the last matching in the enumerable" do
        @context.last.should == @melbourne
      end
    end

  end

  describe "#max" do

    it "returns the max value for the supplied field" do
      @context.max(:number).should == 20
    end

  end

  describe "#min" do

    it "returns the min value for the supplied field" do
      @context.min(:number).should == 1
    end

  end

  describe "#one" do

    context "when the selector is present" do
      before do
        @criteria.where(:street => "Bourke Street")
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end
      it "returns the first matching in the enumerable" do
        @context.one.should == @melbourne
      end
    end

  end

  describe "#page" do

    context "when the page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :page => 5 })
        @criteria.documents = []
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns the page option" do
        @context.page.should == 5
      end

    end

    context "when the page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @criteria.documents = []
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns 1" do
        @context.page.should == 1
      end

    end

  end

  describe "#paginate" do

    before do
      @criteria = Person.criteria.skip(2).limit(2)
      @context = Mongoid::Contexts::Enumerable.new(@criteria)
      @results = @context.paginate
    end

    it "executes and paginates the results" do
      @results.current_page.should == 2
      @results.per_page.should == 2
    end

  end

  describe "#per_page" do

    context "when a limit option exists" do

      it "returns 20" do
        @context.per_page.should == 20
      end

    end

    context "when a limit option does not exist" do

      before do
        @criteria = Person.criteria.limit(50)
        @criteria.documents = []
        @context = Mongoid::Contexts::Enumerable.new(@criteria)
      end

      it "returns the limit" do
        @context.per_page.should == 50
      end

    end

  end

  describe "#sum" do

    it "returns the sum of all the field values" do
      @context.sum(:number).should == 51
    end

  end

  context "#id_criteria" do

    let(:criteria) do
      criteria = Mongoid::Criteria.new(Address)
      criteria.documents = []
      criteria
    end
    let(:context) { criteria.context }

    context "with a single argument" do

      let(:id) { BSON::ObjectID.new.to_s }

      before do
        criteria.expects(:id).with(id).returns(criteria)
      end

      context "when the document is found" do

        let(:document) { stub }

        it "returns a matching document" do
          context.expects(:one).returns(document)
          document.expects(:blank? => false)
          context.id_criteria(id).should == document
        end

      end

      context "when the document is not found" do

        it "raises an error" do
          context.expects(:one).returns(nil)
          lambda { context.id_criteria(id) }.should raise_error
        end

      end

    end

    context "multiple arguments" do

      context "when an array of ids" do

        let(:ids) do
          (0..2).inject([]) { |ary, i| ary << BSON::ObjectID.new.to_s }
        end

        context "when documents are found" do

          let(:docs) do
            (0..2).inject([]) { |ary, i| ary << stub }
          end

          before do
            criteria.expects(:id).with(ids).returns(criteria)
          end

          it "returns matching documents" do
            context.expects(:execute).returns(docs)
            context.id_criteria(ids).should == docs
          end

        end

        context "when documents are not found" do

          it "raises an error" do
            context.expects(:execute).returns([])
            lambda { context.id_criteria(ids) }.should raise_error
          end

        end

      end

      context "when an array of object ids" do

        let(:ids) do
          (0..2).inject([]) { |ary, i| ary << BSON::ObjectID.new }
        end

        context "when documents are found" do

          let(:docs) do
            (0..2).inject([]) { |ary, i| ary << stub }
          end

          before do
            criteria.expects(:id).with(ids).returns(criteria)
          end

          it "returns matching documents" do
            context.expects(:execute).returns(docs)
            context.id_criteria(ids).should == docs
          end

        end

        context "when documents are not found" do

          it "raises an error" do
            context.expects(:execute).returns([])
            lambda { context.id_criteria(ids) }.should raise_error
          end

        end

      end
    end

  end

end
