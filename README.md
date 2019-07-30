# Fork of H2, the Java SQL database.

This is a fork of H2 database based on H2 1.4.199 version and adapted to use in Apache Ignite
project as a dependency for ignite-indexing module.

Reverted commits:
1. Multi-statement optimization was reverted, as it broke multistatement support in JDBC in Ignite
ad requires big changes to fix.
2. Do not convert standard TRIM function to non-standard functions. Breaks tests and compatibility.


Note: As Apache Ignite uses only in-memory H2 features, some useless sources may be dropped.
E.g. full-text and geo search, transactions support, disk stores, android, some docs and tests.

More information about original project: http://h2database.com