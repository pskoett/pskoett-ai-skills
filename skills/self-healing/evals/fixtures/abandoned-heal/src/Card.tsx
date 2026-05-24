import React from "react";

// Pretend this is a Card component used widely across the app.
// Note: it pulls `Date.now()` and `crypto.randomUUID()` directly — both are
// non-deterministic, both end up in the rendered output, both feed snapshots.
export function Card({ title }: { title: string }) {
  const id = crypto.randomUUID();
  const renderedAt = new Date(Date.now()).toISOString();
  return (
    <article data-id={id} data-rendered-at={renderedAt}>
      <h2>{title}</h2>
    </article>
  );
}
