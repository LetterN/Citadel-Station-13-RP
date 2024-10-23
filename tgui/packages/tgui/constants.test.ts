import {
  getGasColor,
  getGasFromId,
  getGasFromPath,
  getGasLabel,
} from './constants';

describe('gas helper functions', () => {
  it('should get the proper gas label', () => {
    const gasId = 'phoron';
    const gasLabel = getGasLabel(gasId);
    expect(gasLabel).toBe('PHR');
  });

  it('should get the proper gas label with a fallback', () => {
    const gasId = 'nonexistent';
    const gasLabel = getGasLabel(gasId, 'fallback');

    expect(gasLabel).toBe('fallback');
  });

  it('should return none if no gas and no fallback is found', () => {
    const gasId = 'nonexistent';
    const gasLabel = getGasLabel(gasId);

    expect(gasLabel).toBe('None');
  });

  it('should get the proper gas color', () => {
    const gasId = 'phoron';
    const gasColor = getGasColor(gasId);

    expect(gasColor).toBe('pink');
  });

  it('should return a string if no gas is found', () => {
    const gasId = 'nonexistent';
    const gasColor = getGasColor(gasId);

    expect(gasColor).toBe('black');
  });

  it('should return the gas object if found', () => {
    const gasId = 'phoron';
    const gas = getGasFromId(gasId);

    expect(gas).toEqual({
      id: 'phoron',
      path: '/datum/gas/phoron',
      name: 'Phoron',
      label: 'PHR',
      color: 'pink',
    });
  });

  it('should return undefined if no gas is found', () => {
    const gasId = 'nonexistent';
    const gas = getGasFromId(gasId);

    expect(gas).toBeUndefined();
  });

  it('should return the gas using a path', () => {
    const gasPath = '/datum/gas/phoron';
    const gas = getGasFromPath(gasPath);

    expect(gas).toEqual({
      id: 'phoron',
      path: '/datum/gas/phoron',
      name: 'Phoron',
      label: 'PHR',
      color: 'pink',
    });
  });
});
