# Flight Booking SQL Database

## Overview

A SQL Server database system designed to support an airline and airport ticketing and reservation workflow.

The system covers passenger reservations, ticket issuance, baggage handling, additional services, employee authentication, business rules, data integrity, query execution, and database security.

## Objectives

- Design a normalised airline reservation database.
- Model relationships between passengers, flights, reservations, tickets, employees, and baggage.
- Enforce business rules using database constraints and triggers.
- Implement stored procedures, views, and functions.
- Support ticketing and additional services.
- Demonstrate transaction and concurrency considerations.
- Apply database security and backup/recovery practices.
- Generate business insights from reservation data.

## Database Entities

The system contains eight main tables:

- Passenger
- Flight
- Reservation
- Ticket
- Employee
- Employee Authentication
- Additional Services
- Baggage

### Key Relationships

- One passenger → many reservations
- One flight → many reservations
- One reservation → one ticket
- One employee → many tickets
- One ticket → many baggage records
- One ticket → one additional-services record

## Business Rules

The system supports:

- Passenger Name Record (PNR) identification
- Reservation statuses
- Ticket issuance
- Seat allocation
- Baggage tracking
- Additional baggage charges
- Upgraded meals
- Preferred seating
- Employee authentication
- Role-based access design
- Data validation

Additional-service pricing includes:

- Extra luggage: £100 per kg above the 20 kg allowance
- Upgraded lunch: £20 per person
- Preferred seating: £30 per person

## Database Design

The database follows Third Normal Form (3NF) to reduce redundancy and improve data integrity.

Primary keys and foreign keys maintain referential integrity, while check constraints and triggers enforce business rules.

## SQL Features

The project demonstrates:

- T-SQL
- Primary and foreign keys
- Check constraints
- Stored procedures
- User-defined functions
- Views
- Triggers
- Transactions
- Data validation
- Query optimisation
- Security considerations
- Backup and recovery planning

## Example Business Queries

The database supports questions such as:

- Which passengers have pending reservations?
- Which passengers are over 40?
- Which passengers spent more than £1,000?
- Which passengers require specific meal services?
- How can passengers be searched by surname?
- How can new employees be inserted?
- How can passenger information be updated?
- How can baggage rules be enforced?

These queries connect database operations to customer service, revenue management, and operational decision-making.

## Security

The design considers:

- Employee authentication
- Role-based access
- Protection of sensitive fields
- Stored procedures for controlled data modification
- Validation triggers
- Database-level business rules

The project documentation notes that role-based access was designed into the schema but was not fully enforced programmatically in the implementation.

## Backup & Recovery

Recommended production practices include:

- Daily full backups
- Differential backups
- Transaction-log backups
- Off-site/cloud backup storage
- Automated integrity checks
- SQL Server Agent jobs

## Tools

- SQL Server
- T-SQL
- Relational database design
- Stored procedures
- Triggers
- Views
- User-defined functions
- Query optimisation

## Conclusion

This project demonstrates the design and implementation of a relational airline ticketing and reservation database, combining database architecture with operational business rules, analytical queries, security considerations, and performance optimisation.
