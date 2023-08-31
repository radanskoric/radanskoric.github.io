---
layout: post
title:  "PostgreSQL zero-downtime migration of a primary key from int to bigint (with Ruby on Rails specific notes)!"
date:   2022-02-23
categories: postgresql rails
---

_**Preface: I wrote this post for [the Silverfin engineering blog](https://engineering.silverfin.com/pg-zero-downtime-bigint-migration/) and replicated it here on my personal blog with permission.**_

“90% what?” “I said this table is at 90%.” “Of what?” “Of int values for its primary key.” “That .. doesn’t sound good.” “No, if it gets to 100% we’re down.” “That’s not good.” “No, captain obvious.” “So what do we do?” “We have to migrate it to bigints.” “And all its foreign keys?” “Yes.” “No downtime?” “No downtime.” “That will be fun.” “For some definition of fun.” “When do we start?” “We don’t.” “What?” “We’re fictional characters in a bad attempt to make a dry topic more interesting.” “Oh.” “We don’t even have names.” “Oh ... what now?” “The paragraph is coming to an end soon, I think the real content will start.” “And what about us?” “I guess we then cease to exist.” “No, I mean ... about us?” “Us?” “I ... , I love you ...” “...”

## The problem

You have an auto increment primary key int field and it’s nearing the maximum value for int: 2,147,483,647. If you run out of the values your PostgreSQL installation will go into a forced shutdown, most likely taking your application with it. The solution is, of course, to change the primary key to a bigint. However, if you’re running out of INTs, chances are that your table is also very large and a simple ALTER COLUMN command will take hours to run. Since it will lock the whole table it will require you to plan a maintenance window. If you can’t afford a multi-hour maintenance window, like most applications can’t, you have to go down a more complicated route of doing this with zero downtime. It’s a little dance you have to do with the database and when done right the database rewards you with none of the customers noticing anything is happening. Let me show you how.

## The plan

From a very high level the plan is rather simple:

1. Setup a new_id bigint field and have all new records automatically mirror the value of id to new_id.
1. Backfill all old records and concurrently build a unique index over new_id. This phase can run for however long is needed, even days, all without downtime. The mirroring from step 1 ensures that new records on the table don’t violate the uniqueness of the index while we are doing the work.
1. In a similar fashion migrate all foreign keys and have their constraints point only to the new primary column.
1. In one fast atomic transaction swap new_id and id and drop the old integer column.

Ta da! Zero downtime. Details follow.

The bulk of the content is in pure SQL so that it is useful no matter what language and framework you are using since the technique is more about PostgreSQL than anything else. However, I made the migration while working on a Ruby on Rails application so I’ve added some notes on how to deal with Rails specific issues along the way.

For reference, this migration was performed on PostgreSQL 13 and Rails 6.1.

## Primary key setup

We first set up a new bigint field that is not null and has a default value of 0. The default value is there to give us a free NOT NULL constraint. Since PostgreSQL 11, when a new field with a default value is added, it will be a fast metadata only operation. In addition it means that NOT NULL can be added at the metadata level only making the whole thing a very fast change regardless of table size. Later, when we backfill all values, we can get rid of the default value:

```sql
ALTER TABLE "table" ADD "new_id" bigint DEFAULT 0 NOT NULL;
```

In order to ensure we automatically get `id` mirrored to `new_id` for all new records we will use database triggers:

```sql
CREATE OR REPLACE FUNCTION mirror_table_id_to_new_id()
  RETURNS trigger AS
$BODY$
BEGIN
  NEW.new_id = NEW.id;

  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;;

CREATE TRIGGER table_new_id_trigger
  BEFORE INSERT
  ON table
  FOR EACH ROW
  EXECUTE PROCEDURE mirror_table_id_to_new_id();
```

At this point you can be certain that PostgreSQL will ensure that all new rows that are inserted will have an identical value in both `id` and `new_id` fields.

### Ruby On Rails notes

Adding the column will work with a simple `add_column(:table, :new_id, :bigint, default: 0, null: false)` but there is currently no helper function for creating functions and triggers so you’ll need to execute raw SQL.

## Primary key shape up

The next part is shaping up the new field to be functionally identical to the primary key. This involves:

1. Backfilling the `new_id` column so it matches `id` for all rows in the table.
1. Dropping the default value since it’s not longer needed.
1. Adding a unique index over the `new_id` field. This is possible because, with the db trigger, after the backfill all values will be unique.

Theoretically backfilling is as simple as `UPDATE table SET new_id = id WHERE new_id = 0`  but this will very likely be a very slow operation if you have a large table. Also you don’t want to lock up all the rows with one command as that will not play nicely with regular usage while the application is running.  An approach is to have a loop that continuously  selects a batch of ids and then updates them before moving on to the new batch:
`SELECT id FROM table WHERE new_id = 0 LIMIT 10000`. You might expect that this will be inefficient because we don’t yet have an index on `new_id`. However, PostgreSQL will most likely decide to do a table scan and it will collect rows until it has 10000 rows but since your oldest rows will usually be exactly the ones that have `new_id = 0` the first 10000 rows it looks at will happen to match the criteria and it will run reasonably fast, then the next 10000 will match and so on. I wrote usually because there are [some caveats](https://www.postgresql.org/docs/14/runtime-config-compatible.html?ref=engineering.silverfin.com#GUC-SYNCHRONIZE-SEQSCANS) so make sure to monitor the backfill process while you’re running it on your production.

When you’ve backfilled the values you can now drop the default value on the column:
```sql
ALTER TABLE table ALTER COLUMN new_id DROP DEFAULT
```

And you can now also create a unique index over the new field. To do it zero-downtime we’ll create it concurrently:
```sql
CREATE UNIQUE INDEX CONCURRENTLY table_bigint_pkey ON table(new_id)
```
Note that concurrent index creation can fail and in that case it will leave an `INVALID` index which has to be cleaned up. In this particular case it is very unlikely because the db trigger ensures that the uniqueness constraint from the primary key is mirrored into the new field but still make sure to check that the index was created successfully.

This unique index is key to having the last step be a very fast metadata only change. As you’ll see, PostgreSQL allows us to convert it into a primary key constraint.

### Ruby on Rails notes

You can leverage Rails helpers for the backfill:
```ruby
model.where(new_id: 0).in_batches(of: 10_000) do |relation|
  relation.update_all("new_id = id")
end
```

Dropping the default can be done in a database migration:
```ruby
change_column_default :table, :new_id, from: 0, to: nil
```
At this point you will run into a little issue with Rails fixtures, if you use them. When Rails loads fixtures it disables all constraints and triggers so that it doesn’t run into foreign key issues when the data is partially loaded. This unfortunately means that the value propagation trigger we set up will not run when fixtures are being loaded and then later it will fail because the new column will be nil. The simplest way to fix this is to define the new column in fixtures. The values don’t need to actually match for now so to make it not null and unique you can simply set it up like this:
```ruby
<% next_new_id = 0 %>
#...
  new_id: <%= next_new_id += 1 %>
#...
  new_id: <%= next_new_id += 1 %>
```

Creating an index concurrently can also be done in a database migration with standard Rails helpers:
```ruby
add_index :table, :new_id, unique: true, algorithm: :concurrently
```

## Foreign Keys

If you have any foreign keys pointing at the primary key now you must redirect your attention to them and migrate all of them. You can’t even finish the migration of the primary key before doing that. The reason is that you can’t get rid of the primary key constraint on the old field to move it to the new field while there are still foreign keys referencing it.

The complete plan for the foreign keys is as follows:

1. Set up bigint field `new_fk_id`. Make sure to copy existing constraints, including `NOT NULL`. If it doesn’t have a default value, set default to 0. If `fk_id` can be null then your situation is simpler and you can also allow null on the new field.
1. Install db triggers to set `new_fk_id` to same value as `fk_id` on every create or update.
1. Backfill the `new_fk_id` values to match `fk_id`. If you had a temporary default value of 0 to bootstrap the `NOT NULL` constraint, you can drop the default value now.
1. If the field has an index on it, build the index concurrently. Since you will be adding a foreign key constraint you will most likely want to add an index to speed up foreign key checks, unless the foreign key table is very small.
1. Add not valid foreign key on `new_fk_id` pointing to `new_id` with `ON DELETE` setting matching the one on `fk_id`.
1. Validate the new foreign key.
1. Rename the keys to “shift” the new one into place: `fk_id -> old_fk_id` and `new_fk_id -> fk_id`.
1. When you verify that everything is correct, drop the old field.

## Foreign Key Setup

I’ll now explain the first 3 steps here. The case where we have a not null value with no default is the most complex one so I’ll just assume that one going forward.

First just as before we create a new field:
```sql
ALTER TABLE fk_table ADD new_fk_id bigint DEFAULT 0 NOT NULL;
```

Unlike primary keys, foreign keys can usually be updated as well so we need to have both a create and update trigger:
```sql
CREATE OR REPLACE FUNCTION mirror_fk_table_fk_id_to_new_fk_id()
  RETURNS trigger AS
$BODY$
BEGIN
  NEW.new_fk_id = NEW.fk_id;

  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;;

CREATE TRIGGER fk_table_new_fk_id_trigger
  BEFORE INSERT
  ON fk_table
  FOR EACH ROW
  EXECUTE PROCEDURE mirror_fk_table_fk_id_to_new_fk_id();

CREATE TRIGGER update_fk_table_new_fk_id_trigger
  BEFORE UPDATE
  ON fk_table
  FOR EACH ROW
  WHEN (OLD.fk_id IS DISTINCT FROM NEW.fk_id)
  EXECUTE PROCEDURE mirror_fk_table_fk_id_to_new_fk_id();
```

## Foreign Key Shape Up

On this step we have to do almost the same things we did for the primary key: backfill and build an index. For the backfill you can proceed exactly as you did for the primary index, just assign the new column from old to new field.

After backfilling is finished if you had a temporary `0` value to go around the `NOT NULL` constraint this is the time to drop it, just like you did for the primary key. If you didn’t have it then you can simply move on.

After that is done proceed to build an index concurrently. Most likely the only difference will be that this index will not need to be unique.

## Foreign Key Finalisation

Since it’s a foreign key we need to create a foreign key pointing to the new primary key we have already created. It is important that we are doing this after the table has been backfilled and the index created because as soon as we have the foreign key set up cascade checks will start running and without the index they will be very slow. Normally, creating a foreign key will lock up the table and on a large table this will make it not be zero downtime. To go around that we will first create a `NOT VALID` foreign key. This means that the database will only validate it on new rows and row updates. After we backfill the values we will be able to validate it. Validating an existing foreign key will not lock up the table, making the whole operation be zero downtime:
```sql
ALTER TABLE fk_table
  ADD CONSTRAINT fk_new_fk_id FOREIGN KEY (new_fk_id)
  REFERENCES table (new_id)
  ON DELETE CASCADE
  NOT VALID;
```

After that you can validate the foreign key. This will not lock up the whole table so it is zero downtime:
```sql
ALTER TABLE fk_table VALIDATE CONSTRAINT fk_new_fk_id;
```

At this point everything is set up and we have a fully functioning new foreign key column that is identical to the original in every way except being a bigint. This means that we can in one transaction “shift” the new column in place of the old without the application code noticing anything happened. We will first remove the propagation we set up because we don’t need it any more and then we’ll rename the columns around to end up with integer column `old_id` and a bigint column `new_id`. The following has to be executed in a single transaction:
```sql
DROP TRIGGER fk_table_new_fk_id_trigger ON fk_table;
DROP TRIGGER update_fk_table_new_fk_id_trigger ON fk_table;
DROP FUNCTION mirror_fk_table_fk_id_to_new_fk_id();

ALTER TABLE fk_table RENAME COLUMN fk_id TO old_fk_id;
ALTER TABLE fk_table RENAME COLUMN new_fk_id TO fk_id;
```

Since this is only manipulating the table metadata it will be a very fast change, regardless of table size. If you want to be extra safe you can now set up propagation of values from `fk_id` to `old_fk_id` in the same transaction. This will allow you to revert back easily if needed knowing that the fields are still in sync.

### Ruby on Rails Notes

Remember the fixtures issue from before where we assigned some unique numbers to the new primary key and we said it doesn’t need to match? Well, after we add the foreign key the numbers need to match or we will fail when trying to run the tests that create rows with a foreign key because the primary table will not have `new_id` matching `id`. The fix is to correct that **after** the fixtures are loaded which can be done by defining an extension for fixtures loading task in a new file we’ll create `lib/tasks/db.rake`:
```ruby
Rake::Task["db:fixtures:load"].enhance do
  Table.update_all("new_id = id")
end
```

This will ensure that the test database is in order before we start running our tests. The triggers will work again and will take care of the rest.

## Primary Key Finalisation

Finalising the primary key is pretty similar to the foreign key finalisation with the added twist of correctly replacing the primary key. All of the steps executed here should be executed in a single transaction, just like when we finalised the foreign key migration. Likewise, all of the changes are very fast metadata changes, making this a zero downtime migration.

Just like we did for the foreign key we start by dropping the db triggers and by renaming the columns to shift `new_id` into place and move the old `id` out of the way into `old_id`:
```sql
DROP TRIGGER table_new_id_trigger ON table;
DROP FUNCTION mirror_table_id_to_new_id();

ALTER TABLE table RENAME COLUMN id TO old_id;
ALTER TABLE table RENAME COLUMN new_id TO id;
```

Once we’ve done that the now renamed `old_id` field still owns the primary key sequence so we need to switch ownership and also remove the default value from it so it is no longer using the primary key sequence:
```sql
ALTER SEQUENCE table_id_seq OWNED BY table.id;
ALTER TABLE table ALTER COLUMN old_id DROP DEFAULT;
```

Now finally you can move the primary key from the old to the new field. Normally adding a primary key constraint requires an underlying unique index to be built. However, you can tell it to use an existing unique index which makes the operation a fast metadata only change. This is also why it was important that we built this index before:
```sql
ALTER TABLE table
  DROP CONSTRAINT table_pkey,
  ADD CONSTRAINT table_pkey PRIMARY KEY USING INDEX table_bigint_pkey,
  ALTER COLUMN id SET DEFAULT nextval('table_id_seq'::regclass);
```

At this point you can also just drop the `old_id` column because you don’t need it anymore. I like to keep it alive for a short time just in case we need to revert for some reason. If you also decide to keep it around, note that it’s a not null column that’s not getting any values so you will want to create the mirroring function and trigger from `id` to `old_id`, just like we did before for `new_id`.

Once you see that all is working ok you can finish by cleaning up all of the temporary artifacts: the db triggers and `old_` columns. Also cleanup all of the temporary fixes you had to put in place to keep tests based on fixtures working correctly during the intermediate steps.

## Conclusion

The whole procedure is pretty involved with a lot of intermediary steps, especially if you have a lot of foreign keys referencing the primary key. However, the migration is doable and can be done safely with zero customer impact. If your site is large enough usually the extra effort of doing it zero downtime will be worth it.
