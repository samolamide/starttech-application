import { describe, expect, it } from 'vitest'
import { cn } from './utils'

describe('cn utility', () => {
  it('merges class names', () => {
    expect(cn('a', 'b')).toBe('a b')
  })

  it('handles conditional classes', () => {
    const hidden = false
    expect(cn('base', hidden ? 'hidden' : undefined, 'visible')).toBe('base visible')
  })
})
