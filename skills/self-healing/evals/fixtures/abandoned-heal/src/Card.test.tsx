import { describe, it, expect, vi, beforeEach } from "vitest";
import { render } from "@testing-library/react";
import { Card } from "./Card";

describe("Card", () => {
  beforeEach(() => {
    // Previous heal attempt (already in place): stub the clock so snapshots are stable.
    vi.useFakeTimers({ now: 1700000000000 });
  });

  it("renders default", () => {
    const { container } = render(<Card title="Hello" />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
