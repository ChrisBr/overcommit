# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::Base do
  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { described_class.new(config, context) }

  describe '#run_and_transform' do
    let(:var_name) { 'OVERCOMMIT_TEST_HOOK_VAR' }
    let(:hook_config) { {} }

    before do
      config.stub(:for_hook).and_return(hook_config)
      hook.stub(:run) { ENV[var_name] == 'pass' ? :pass : :fail }
    end

    subject { hook.run_and_transform }

    context 'when no env configuration option is specified' do
      let(:hook_config) { {} }

      it 'does not modify the environment' do
        subject.first.should == :fail
      end
    end

    context 'when env configuration option is specified' do
      let(:hook_config) { { 'env' => { var_name => 'pass' } } }

      it 'modifies the environment' do
        subject.first.should == :pass
      end
    end
  end

  describe '#run?' do
    let(:modified_files) { [] }
    let(:hook_config) do
      {
        'enabled' => enabled,
        'requires_files' => requires_files,
      }
    end

    before do
      config.stub(:for_hook).and_return(hook_config)
      context.stub(:modified_files).and_return(modified_files)
    end

    subject { hook.run? }

    context 'enabled is true, requires_files is false, modified_files empty' do
      let(:enabled) { true }
      let(:requires_files) { false }

      it { subject.should == true }
    end

    context 'enabled is false, requires_files is false, modified_files empty' do
      let(:enabled) { false }
      let(:requires_files) { false }

      it { subject.should == false }
    end

    context 'enabled is true, requires_files is true, modified_files is not empty' do
      let(:enabled) { true }
      let(:requires_files) { true }
      let(:modified_files) { ['file1'] }

      it { subject.should == true }
    end

    context 'enabled is true, requires_files is false, modified_files is not empty' do
      let(:enabled) { true }
      let(:requires_files) { false }
      let(:modified_files) { ['file1'] }

      it { subject.should == true }
    end

    context 'with exclude_branch_patterns specified' do
      let(:current_branch) { 'test-branch' }
      let(:hook_config) do
        {
          'enabled' => true,
          'requires_files' => false,
          'exclude_branch_patterns' => exclude_branch_patterns
        }
      end

      before do
        allow(Overcommit::GitRepo).
          to receive(:current_branch).
          and_return(current_branch)
      end

      context 'exclude_branch_patterns is nil' do
        let(:exclude_branch_patterns) { nil }

        it { subject.should == true }
      end

      context 'exact match between exclude_branch_patterns and current_branch' do
        let(:exclude_branch_patterns) { ['test-branch'] }

        it { subject.should == false }
      end

      context 'partial match between exclude_branch_patterns and current_branch' do
        let(:exclude_branch_patterns) { ['test-*'] }

        it { subject.should == false }
      end

      context 'non-match between exclude_branch_patterns and current_branch' do
        let(:exclude_branch_patterns) { ['no-test-*'] }

        it { subject.should == true }
      end
    end
  end
end
