-- Creating Database
Create Database FlightBookingSystem;

-- Using FlightBookingSystem database
use FlightBookingSystem;

-- Tables: Passenger, Employee, Flight, Ticket, Reservation, Baggage, Additional Services
-- Passenger Table
Create table Passenger(
		PassengerId int primary key identity(1,1),
		PNR nvarchar(10) unique not null,
		FirstName nvarchar(50) not null,
		LastName nvarchar(50) not null,
		Email nvarchar(50) unique not null,
		DateOfBirth date	not null,
		MealPreference nvarchar(15) check (MealPreference in ('Vegetarian', 'Non-Vegetarian')),
		EmergencyContact nvarchar(20) null)

-- Flight Table
Create table Flight(
		FlightId int primary key identity(1,1),
		FlightNumber nvarchar(10) unique not null,
		Origin nvarchar(20) not null,
		Destination nvarchar(20) not null,
		DepartureTime Datetime not null,
		ArrivalTime Datetime not null)

-- Reservation Table 
Create table Reservation(
		ReservationId int primary key identity(1,1),
		PNR nvarchar(10) not null foreign key(PNR) references Passenger(PNR),
		PassengerId int not null foreign key(PassengerId) references Passenger(PassengerId),
		FlightId int not null foreign key(FlightId) references Flight(FlightId),
		BookingDate Date not null check(BookingDate >=getdate()),
		BookingStatus nvarchar(10) check(BookingStatus in ('Confirmed', 'Pending', 'Cancelled'))) 

-- Ticket Table
Create table Ticket(
		TicketId int primary key identity(1,1),
		ReservationId int not null foreign key(ReservationId) references Reservation(ReservationId),
		IssueDate Date default getdate(),
		IssueTime Time default getdate(),
		SeatNumber nvarchar(5) null,
		Class nvarchar(15) check(Class in ('Economy', 'Business', 'First-Class')),
		Fare decimal(10,2) not null,
		EmployeeId int not null foreign key(EmployeeId) references Employee(EmployeeId))

-- Employee Table
Create table Employee (
    EmployeeId int primary key identity(1,1),
    EmployeeName nvarchar(100) not null,
    EmployeeEmail nvarchar(100) unique not null,
    EmployeeRole nvarchar(20) check (EmployeeRole in ('Ticketing Staff', 'Ticketing Supervisor'))
	);

-- Baggage Table
Create table Baggage (
    BaggageId int primary key identity(1,1),
    TicketId int not null foreign key(TicketId) references Ticket(TicketId),
    BaggageWeight decimal(5,2) check (BaggageWeight >= 0),
    BaggageStatus nvarchar(10) check (BaggageStatus IN ('Checked-In', 'Loaded')),
    BaggageFee decimal(10,2) default 0);

--Additional Services Table
Create table AdditionalServices (
    ServiceId int primary key identity(1,1),
    TicketId int not null foreign key(TicketId) references Ticket(TicketId),
    ExtraBaggage decimal(5,2) default 0,  
    UpgradedMeal bit default 0,  
    PreferredSeat bit default 0,  
    TotalAdditionalFare decimal(10,2) not null);

-- Authentication table for storing staff login
Create table EmployeeAuthentication (
    AuthId int primary key identity(1,1),
    EmployeeId int not null foreign key(EmployeeId) references Employee(EmployeeId),        -- Foreign key reference to Employee table
    Username nvarchar(50) not null,                                                                                             -- Username for login
    HashedPassword binary(64) not null,                                                                                      -- Hashed password 
    Salt nvarchar(40) not null,                                                                                                        -- Salt for password hashing 
);


-- Set employee password automatically
Create procedure AddAuthenticationForEmployee
    @EmployeeId int,
    @Username nvarchar(50),
    @Password nvarchar(50)
as
begin
    set nocount on;
    -- Check if employee exists
    If not exists (select 1 from Employee where EmployeeId = @EmployeeId)
    begin
        raiserror('Employee does not exist.', 16, 1);
        return;
    end
    -- Check if username already used
    If exists (select 1 from EmployeeAuthentication where Username = @Username)
    begin
        raiserror('Username already taken.', 16, 1);
        return;
    end
    declare @Salt uniqueidentifier = NEWID();
    declare @SaltStr nvarchar(36) = CAST(@Salt as nvarchar(36));
    declare @HashedPassword binary(64);

    Set @HashedPassword = HASHBYTES('SHA2_512', @Password + @SaltStr);

    -- Insert into Authentication table
    Insert into EmployeeAuthentication (EmployeeId, Username, HashedPassword, Salt)
    values (@EmployeeId, @Username, @HashedPassword, @SaltStr);
end

Exec AddAuthenticationForEmployee
    @EmployeeId = 1,
    @Username = 'SL201',
    @Password = 'LewisP@ssword!';




-- Login(when the staff wants to login in the system)
Create procedure AuthenticateEmployee
    @Username nvarchar(50),
    @Password nvarchar(100)
as
begin
    Set nocount on;
    declare @StoredSalt nvarchar(40);
    declare @StoredHash binary (64);
    declare @ComputedHash binary(64);
    declare @EmployeeId int;

    -- Get salt and hash for the provided username
    Select top 1 
        @StoredSalt = Salt,
        @StoredHash = HashedPassword,
        @EmployeeId = EmployeeId
    from EmployeeAuthentication
    where Username = @Username;

    -- If no matching user, return error
    If @StoredSalt is null
    begin
        print 'Authentication failed: User not found.';
        return;
    end
    -- Recompute hash using input password + stored salt
    set @ComputedHash = HASHBYTES('SHA2_512', @Password + @StoredSalt);
    -- Compare the hashes
    If @ComputedHash = @StoredHash
    begin
        -- Authentication successful — fetch and return details
        Select
            e.EmployeeId,
            e.EmployeeName,
            e.EmployeeEmail,
            e.EmployeeRole
        from Employee e
        where e.EmployeeId = @EmployeeId;
    end
    else
    begin
        -- Authentication failed — wrong password
        print 'Authentication failed: Incorrect password. Ticketing Supervisor may intervene.';
    end
end

Exec AuthenticateEmployee
@username='SL201',
@Password='NewSecurePass123'



-- checking role and granting permission
-- Only Ticketing Supervisor can reset passwords
Create  procedure ResetEmployeePassword
    @SupervisorId int,
    @TargetEmployeeId int,
    @NewPassword nvarchar(100)
as
begin
    declare @SupervisorRole nvarchar(20);
    declare @HashedPassword binary(64);
	declare @Salt uniqueidentifier = NEWID();
    declare @SaltStr nvarchar(36) = CAST(@Salt as nvarchar(36));

    -- Check if the supervisor exists and has the right role
    Select @SupervisorRole = EmployeeRole
    from Employee
    where EmployeeId = @SupervisorId;

    If @SupervisorRole is null
    begin
        throw 50001, 'Supervisor not found.', 1;
        return;
    end

    If @SupervisorRole != 'Ticketing Supervisor'
    begin
        throw 50002, 'Permission denied. Only Ticketing Supervisors can reset passwords.', 1;
        return;
    end

    -- Hash the new password
    Set @HashedPassword = HASHBYTES('SHA2_512', @NewPassword + @SaltStr);

    -- Update the password for the target employee
    Update EmployeeAuthentication
    Set
			HashedPassword = @HashedPassword,
			Salt = @SaltStr
    where EmployeeId = @TargetEmployeeId;

    select 'Password reset successfully by Supervisor.' as message;
end;


-- Supervisor (EmployeeId 2) resets password for EmployeeId 1
Exec ResetEmployeePassword @SupervisorId = 2, @TargetEmployeeId = 1, @NewPassword = 'NewSecurePass123';



-- Inserting data into tables
-- Passenger Table
Insert into Passenger (PNR, FirstName, LastName, Email, DateOfBirth,MealPreference, EmergencyContact)
values ('PNR001', 'John', 'Smith', 'john.smith@email.com',	'1980-05-12',	'Vegetarian', '1234567890'),
('PNR002',	'Alice',	'Brown',	'alice.brown@email.com',	'1992-07-19',	'Non-Vegetarian',	'2345678901'),
('PNR003',	'Robert',	'White',	'robert.white@email.com',	'1978-10-21',	'Vegetarian',	'3456789012'),
('PNR004',	'Emily',	'Johnson',	'emily.johnson@email.com',	'1985-12-03',	'Non-Vegetarian',	'4567890123'),
('PNR005',	'William',	'Davis',	'william.davis@email.com',	'1995-09-17',	'Vegetarian',	'5678901234'),
('PNR006', 'Sophia', 'Miller', 'sophia.miller@email.com',	 '2000-03-25',	'Non-Vegetarian', '6789012345'),
('PNR007',	'Michael',	'Wilson',	'michael.wilson@email.com',	'1972-06-30',	'Vegetarian',	'7890123456'),
('PNR008',	'Olivia','	Moore',	'olivia.moore@email.com',	'1988-11-11',	'Non-Vegetarian',	'8901234567'),
('PNR009',	'David',	'Taylor','david.taylor@email.com',	'1975-04-14'	,'Vegetarian',	'9012345678'),
('PNR010',	'Jessica',	'Anderson'	,'jessica.anderson@email.com',	'1990-08-08',	'Non-Vegetarian',	'1234567899')

-- Flight Table 
Insert into Flight (FlightNumber, Origin, Destination, DepartureTime, ArrivalTime)
values
('FL123', 'London', 'Paris', '2025-06-15 10:30:00', '2025-06-15 12:00:00'),
('FL456', 'New York', 'Toronto', '2025-06-16 14:45:00', '2025-06-16 16:30:00'),
('FL789', 'Dubai', 'Mumbai', '2025-06-17 18:00:00', '2025-06-17 21:00:00'),
('FL1122', 'London', 'Delhi', '2025-06-18 10:30:00', '2025-06-18 23:30:00');

-- Resevation Table
Insert into Reservation(PNR, PassengerID,FlightId, BookingDate, BookingStatus)
values ('PNR001', '1', '1', '2025-06-01', 'Confirmed'),
('PNR002', '2', '1', '2025-06-02', 'Pending'),
('PNR003', '3', '2', '2025-06-03', 'Confirmed'),
('PNR004', '4', '2', '2025-06-05', 'Cancelled'),
('PNR005', '5', '3', '2025-06-06', 'Confirmed'),
('PNR006', '6', '4', '2025-06-01', 'Pending'),
('PNR007', '7', '4', '2025-06-01', 'Confirmed'),
('PNR008', '8', '3', '2025-06-02', 'Pending'),
('PNR009', '9', '2', '2025-06-03', 'Pending'),
('PNR010', '10', '1', '2025-06-05', 'Cancelled');

-- Ticket Table
Insert into Ticket(ReservationId, IssueDate, SeatNumber, Class,Fare,EmployeeId)
values ('1',	'2025-06-01',	'A1',	'Economy',	'250',	'1'),
('3',	'2025-06-03',	'B2',	'Business',	'500',	'2'),
('5',	'2025-06-06',	'C3',	'First-Class',	'1000',	'3'),
('7',	'2025-06-01',	'A3',	'Economy',	'500',	'3')

-- Empoyee Table 
Insert into Employee(EmployeeName, EmployeeEmail, EmployeeRole)
values ('Sarah Lewis',	'sarah.lewis@email.com',	'Ticketing Staff'),
('Tom Carter',	'tom.carter@email.com',	'Ticketing Supervisor'),
('Rachel Adams',	'rachel.adams@email.com',	'Ticketing Staff')


-- Baggage Table
Insert into Baggage (TicketId, BaggageWeight, BaggageStatus,BaggageFee)
values ('1',	'18',	'Checked-In',	'0'),
('2',	'25',	'Checked-In',	'500'),
('3',	'30',	'Loaded',	'0'),
('4',	'20',	'Checked-In',	'0')


-- Additional Services
Insert into AdditionalServices (TicketID,ExtraBaggage, UpgradedMeal, PreferredSeat,TotalAdditionalFare)
values ('1',	'0',	'1',	'0',	'20'),
('2',	'5',	'0',	'1',	'530'),
('3',	'0',	'1',	'1',	'50'),
('4',	'0',	'0',	'1',	'30')

-- Checking data insertion
Select * from Passenger
Select * from Employee
Select * from Flight
Select * from Reservation
Select * from Ticket
Select * from Baggage
Select * from AdditionalServices

