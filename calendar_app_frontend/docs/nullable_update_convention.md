# Nullable model updates

For nullable fields in `copyWith` or other model update APIs, use an
`Object?` parameter whose default is a private `_unset` sentinel:

- Omit the argument to preserve the existing value.
- Supply a non-null value to replace it.
- Supply `null` explicitly to clear it.

Update payloads must include a cleared field as `null` when the endpoint uses
`null` to clear values. Existing serializer options determine whether nulls
are included for a particular endpoint.

This convention currently applies only to `Worker`, `BillingProfile`, and
`ClientBilling`.
