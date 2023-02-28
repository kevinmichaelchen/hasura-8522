Minimalist reproduction of
[Hasura Issue 8522](https://github.com/hasura/graphql-engine/issues/8522).

We have a one-to-one relationship between a `person` and their (postal)
`address`.

Doing an idempotent nested insert fails.

## Getting started

Spin up the Docker containers with:

```
make start
```

In another tab, launch the Console UI with:

```
make console
```

## The Mutation

In the GraphiQL playground, run the following mutation, which attempts to do a
nested insert, first creating the **Person**, followed by their postal
**Address**.

The client provides the Person's ID as an
[idempotency key](https://en.wikipedia.org/wiki/Idempotence).
This allows clients to safely retry requests without accidentally performing the
same operation twice.

```graphql
mutation CreatePersonWithAddress {
  insertPerson(
    objects: [
      {
        id: "d86eeb43-536c-46d7-832d-d4e1f9480509"
        name: "John Doe"
        address: {
          data: {
            regionCode: "US"
          }
          onConflict: {
            constraint: address_pkey
            update_columns: [id]
          }
        }
      }
    ]
    onConflict: {
      constraint: person_pkey
      update_columns: [id]
    }
  ) {
    returning {
      id
      name
      address {
        regionCode
      }
    }
  }
}
```

## The Error

"cannot insert object relationship ... as ... column values are already
determined"

```json
{
  "errors": [
    {
      "extensions": {
        "code": "validation-failed",
        "path": "$.selectionSet.insertPerson.args.objects[0].address"
      },
      "message": "cannot insert object relationship \"address\" as \"id\" column values are already determined"
    }
  ]
}
```

## Workarounds

### Workaround 1: Remove the ID

If we remove the idempotency key, and let the database generate the primary key,
the error goes away.

### Workaround 2: Flatten the inserts

Instead of doing a nested insert, we can do a flat insert and still preserve
atomicity:

```graphql
mutation CreatePersonAndAddress {
  people: insertPerson(
    objects: [
      {
        id: "85e76ace-17d8-4134-ba4f-67c86ba5c7bc"
        name: "John Doe"
      }
    ]
    onConflict: {
      constraint: person_pkey
      update_columns: [id]
    }
  ) {
    returning {
      id
      name
    }
  }
  
  addrs: insertAddress(
    objects: [
      {
        regionCode: "US"
        personId: "85e76ace-17d8-4134-ba4f-67c86ba5c7bc"
      }
    ]
    onConflict: {
      constraint: address_pkey
      update_columns: [id]
    }
  ) {
    returning {
      regionCode
    }
  }
}
```
