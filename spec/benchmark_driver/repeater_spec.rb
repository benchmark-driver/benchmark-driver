describe BenchmarkDriver::Repeater do
  describe '.with_repeat' do
    it 'returns an average result correctly' do
      config = BenchmarkDriver::Config::RunnerConfig.new(
        repeat_count: 10,
        repeat_result: 'average',
        run_duration: 1.0,
        timeout: 1.0,
        verbose: 0,
      )
      result = BenchmarkDriver::Repeater.with_repeat(
        config: config,
        larger_better: true,
        rest_on_average: :average,
      ) { [1.0, 2.0] }
      expect(result).to eq(
        BenchmarkDriver::Repeater::RepeatResult.new(
          value: [1.0, 2.0],
          all_values: [1.0] * 10,
        )
      )
    end
  end
end
