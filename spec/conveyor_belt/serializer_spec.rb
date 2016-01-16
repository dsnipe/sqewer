require_relative '../spec_helper'

describe ConveyorBelt::Serializer do
  describe '.default' do
    it 'returns the same Serializer instance' do
      instances = (1..1000).map{ described_class.default }
      instances.uniq!
      expect(instances).to be_one
      
      the_instance = instances[0]
      expect(the_instance).to respond_to(:serialize)
      expect(the_instance).to respond_to(:unserialize)
    end
  end
  
  describe '#serialize' do
    
    it 'serializes a Job that has no to_h support without its kwargs' do
      class JobWithoutToHash
      end
      job = JobWithoutToHash.new
      expect(described_class.new.serialize(job)).to eq("{\"_job_class\":\"JobWithoutToHash\",\"_job_params\":null}")
    end
    
    it 'serializes a Struct along with its members and the class name' do
      class SomeJob < Struct.new :one, :two
      end
      
      job = SomeJob.new(123, [456])
      
      expect(described_class.new.serialize(job)).to eq("{\"_job_class\":\"SomeJob\",\"_job_params\":{\"one\":123,\"two\":[456]}}")
    end
    
    it 'raises an exception if the object is of an anonymous class' do
      s = Struct.new(:foo)
      o = s.new(1)
      expect {
        described_class.new.serialize(o)
      }.to raise_error(described_class::AnonymousJobClass)
    end
  end
  
  it 'is able to roundtrip a job with a parameter' do
    require 'ks'
    
    class LeJob < Ks.strict(:some_data)
    end
  
    job = LeJob.new(some_data: 123)
  
    subject = described_class.new
  
    serialized = subject.serialize(job)
    restored = subject.unserialize(serialized)
  
    expect(restored).to be_kind_of(LeJob)
    expect(restored.some_data).to eq(123)
  end
  
  describe '#unserialize' do
    it 'builds a job without keyword arguments if its constructor does not need any kwargs' do
      class VerySimpleJob; end
      blob  = '{"job_class": "VerySimpleJob"}'
      built_job = described_class.new.unserialize(blob)
      expect(built_job).to be_kind_of(VerySimpleJob)
    end
    
    it 'raises an error if the job does not accept the keeyword arguments given in the ticket' do
      class OtherVerySimpleJob; end
      blob  = '{"job_class": "OtherVerySimpleJob", "foo": 1}'
      
      expect {
        described_class.new.unserialize(blob)
      }.to raise_error(described_class::ArityMismatch)
    end
  end
end
