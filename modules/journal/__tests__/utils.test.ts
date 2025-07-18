import { partitionSoundsArray } from "@/lib/utils";

describe('partitionSoundsArray', () => {
  it('partitions sounds into hourly chunks', () => {
    const sounds = [
      { when: '2022-01-01T00:00:00Z' },
      { when: '2022-01-01T00:30:00Z' },
      { when: '2022-01-01T01:00:00Z' },
      { when: '2022-01-01T01:30:00Z' },
    ];

    const result = partitionSoundsArray(sounds, 'hourly');

    expect(result).toEqual([
      [sounds[0], sounds[1]],
      [sounds[2], sounds[3]],
    ]);
  });

  it('partitions sounds into daily chunks', () => {
    const sounds = [
      { when: '2022-01-01T00:00:00Z' },
      { when: '2022-01-01T12:00:00Z' },
      { when: '2022-01-02T00:00:00Z' },
      { when: '2022-01-02T12:00:00Z' },
    ];

    const result = partitionSoundsArray(sounds, 'daily');

    expect(result).toEqual([
      [sounds[0], sounds[1]],
      [sounds[2], sounds[3]],
    ]);
  });

  it('handles an empty array', () => {
    const result = partitionSoundsArray([], 'hourly');

    expect(result).toEqual([]);
  });
});