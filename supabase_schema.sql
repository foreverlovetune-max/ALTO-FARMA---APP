-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables to ensure clean creation (Warning: this deletes existing data in these tables)
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. Profiles Table (Linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone." 
    ON public.profiles FOR SELECT USING (true);
    
CREATE POLICY "Users can insert their own profile." 
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    oldPrice NUMERIC(10, 2),
    isOffer BOOLEAN DEFAULT false,
    discount TEXT,
    imageColor TEXT NOT NULL,
    imageText TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are viewable by everyone." 
    ON public.products FOR SELECT USING (true);

-- 3. Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Nullable for guest checkout
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    address TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    total NUMERIC(10, 2) NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own orders." 
    ON public.orders FOR SELECT USING (
        auth.uid() = user_id
    );

CREATE POLICY "Anyone can create an order." 
    ON public.orders FOR INSERT WITH CHECK (true);

-- 4. Order Items Table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view items of their own orders." 
    ON public.order_items FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = order_items.order_id
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Anyone can insert order items." 
    ON public.order_items FOR INSERT WITH CHECK (true);


-- 5. Insert Initial Mock Data into Products
INSERT INTO public.products (id, category, name, imageColor, imageText, oldPrice, price, isOffer, discount)
VALUES
    (uuid_generate_v4(), 'Fraldas', 'Fralda Pampers Confort Sec M 84un', 'bg-[#18C3B1]', 'Pampers', 129.90, 99.90, true, '-23%'),
    (uuid_generate_v4(), 'Fraldas', 'Fralda Huggies Supreme Care XG 36un', 'bg-[#FF0000]', 'Huggies', 74.90, 61.90, true, '-18%'),
    (uuid_generate_v4(), 'Higiene', 'Sabonete Johnson''s Hora do Sono 200ml', 'bg-[#9B51E0]', 'Johnson''s', 16.90, 14.29, true, '-15%'),
    (uuid_generate_v4(), 'Medicamentos', 'Dorflex 36 comprimidos', 'bg-[#56CCF2]', 'Dorflex', NULL, 19.90, false, NULL),
    (uuid_generate_v4(), 'Cuidados Pessoais', 'Desodorante Rexona Aero 150ml', 'bg-[#333333]', 'Rexona', NULL, 12.90, false, NULL),
    (uuid_generate_v4(), 'Cuidados Pessoais', 'Absorvente Intimus Tripla Proteção c/16', 'bg-[#EB5757]', 'Intimus', NULL, 6.90, false, NULL),
    (uuid_generate_v4(), 'Higiene', 'Shampoo Elseve Hidra Hialurônico 200ml', 'bg-[#BE95C4]', 'Elseve', NULL, 17.90, false, NULL),
    (uuid_generate_v4(), 'Saúde', 'Ninho Forti+ Integral 380g', 'bg-[#F2C94C]', 'Ninho', 23.90, 18.90, true, '-20%');
